/*
 * $Id: XMReceiverMediaPatch.cpp,v 1.9 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMReceiverMediaPatch.h"

#include <opal/mediastrm.h>
#include <opal/mediacmd.h>

#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

#define XM_PACKET_POOL_GRANULARITY 8
#define XM_FRAME_BUFFER_SIZE 352*288*4

XMReceiverMediaPatch::XMReceiverMediaPatch(OpalMediaStream & src)
: OpalMediaPatch(src)
{
	notifierSet = FALSE;
}

XMReceiverMediaPatch::~XMReceiverMediaPatch()
{
}

void XMReceiverMediaPatch::Main()
{
	// Currently, audio is processed using the default OPAL facilities.
	// Only video is processed using QuickTime
	const OpalMediaFormat & mediaFormat = source.GetMediaFormat();
	if(_XMIsVideoMediaFormat(mediaFormat) == FALSE)
	{
		OpalMediaPatch::Main();
		return;
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// The receiving algorithm tries to achieve best-possible data integrity and builds upon
	// the following assumptions:
	//
	// 1) The chance for packets actually being lost/dropped is very small
	// 2) The chance of packets being delayed across timestamp boundaries is much smaller than
	//    the chance of packets being reordered within the same timestamp (the same video frame)
	//
	// First, the frames will be read and put into a sorted linked list with ascending sequence
	// numbers. If a packet group is complete, the packet payloads are copied together and the
	// resulting frame is sent to the XMMediaReceiver class for decompression and display.
	// A packet group is considered to be complete IF
	//
	// a) The first packet has the next ascending sequence number to the sequence number of the
	//    last packet of the previous packet group or the packet contains the beginning of a
	//    coded frame (picture start codes in H.261 / H.263) AND
	// b) The sequence numbers of the packets in the list are ascending with no sequence number
	//    missing AND
	// c) The last packet has the marker bit set
	//
	// This algorithm makes it possible to process packets of a packet group even if they arrive
	// after the last packet of the packet group with the marker bit set. This works well if
	// assumptions 1) and 2) are true.
	//
	// If a packet group is incomplete and the first packet of the next packet group arrives
	// (indicated by a different timestamp), the incomplete packet group is either dropped
	// or processed, depending on the codec being used. If the incomplete packet group is
	// processed, the processing happens delayed since the first packet of the next packet
	// group arrived, leading to inconstant display intervals. As long as assumption 1)
	// is met, this is not a big drawback.
	//
	// If either packets are missing or the decompression of the frame fails, an
	// fast update request is being sent to the remote party.
	///////////////////////////////////////////////////////////////////////////////////////////////
	
	// Allocating a pool of XMRTPPacket instances to reduce
	// buffer allocation overhead.
	// The pool size increases in steps of 8 packets with an initial size of 8 packets.
	// These 8 packets are allocated initially.
	// The packets 9-xx are allocated on demand
	unsigned allocatedPackets = XM_PACKET_POOL_GRANULARITY;
	XMRTPPacket **packets =  (XMRTPPacket **)malloc(allocatedPackets * sizeof(XMRTPPacket *));
	unsigned packetIndex = 0;
	for(unsigned i = 0; i < allocatedPackets; i++)
	{
		packets[i] = new XMRTPPacket(source.GetDataSize());
	}
	
	BYTE *frameBuffer = (BYTE *)malloc(sizeof(BYTE) * XM_FRAME_BUFFER_SIZE);
	
	// Read the first packet
	BOOL firstReadSuccesful = source.ReadPacket(*(packets[0]));

	if(firstReadSuccesful == TRUE)
	{
		// Tell the media receiver to prepare processing packets
		XMCodecIdentifier codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
		XMVideoSize mediaSize = _XMGetMediaFormatSize(mediaFormat);
		unsigned sessionID = source.GetSessionID();
		RTP_DataFrame::PayloadTypes payloadType = packets[0]->GetPayloadType();
		
		// initialize the packet processing variables
		DWORD currentTimestamp = packets[0]->GetTimestamp();
		WORD firstSeqNrOfPacketGroup = 0;
		XMRTPPacket *firstPacketOfPacketGroup = NULL;
		XMRTPPacket *lastPacketOfPacketGroup = NULL;
		
		_XMStartMediaReceiving(sessionID, codecIdentifier, mediaSize, (unsigned)payloadType);
		
		// loop to receive packets and process them
		do {
			inUse.Wait();
			
			BOOL processingSuccesful = TRUE;
			unsigned numberOfPacketsToRelease = 0;
		
			XMRTPPacket *packet = packets[packetIndex];
			
			packet->next = NULL;
			packet->prev = NULL;
			
			// processing the packet
			DWORD timestamp = packet->GetTimestamp();
			WORD sequenceNumber = packet->GetSequenceNumber();
			
			// take into account that the timestamp might wrap around
			if(timestamp < currentTimestamp && (currentTimestamp - timestamp) > (0x01 << 31))
			{
				// This packet group is already processed
				// By changing the sequenceNumber parameter,
				// we can adjust the expected beginning of
				// the current packet group.
				if(firstSeqNrOfPacketGroup <= sequenceNumber)
				{
					firstSeqNrOfPacketGroup = sequenceNumber + 1;
				}
			}
			else
			{
				// also take into account that the timestamp might wrap around
				if(timestamp > currentTimestamp || (timestamp < currentTimestamp && (currentTimestamp - timestamp) > (0x01 << 31)))
				{
					if(firstPacketOfPacketGroup != NULL)
					{
						cout << "Discarding old packet group" << endl;
						firstSeqNrOfPacketGroup = lastPacketOfPacketGroup->GetSequenceNumber() + 1;
						firstPacketOfPacketGroup = NULL;
						lastPacketOfPacketGroup = NULL;
						processingSuccesful = FALSE;
						
						// There are (packetIndex + 1) packets in the buffer, but only the last one
						// ist still needed
						numberOfPacketsToRelease = packetIndex;
					}
				
					currentTimestamp = timestamp;
				}
				
				if(lastPacketOfPacketGroup != NULL)
				{
					XMRTPPacket *previousPacket = lastPacketOfPacketGroup;
					
					do {
						WORD previousSequenceNumber = previousPacket->GetSequenceNumber();
						
						// take into account that the sequence number might wrap around
						if(sequenceNumber > previousSequenceNumber || 
						   (sequenceNumber < previousSequenceNumber && (previousSequenceNumber - sequenceNumber) > (0x01 << 15)))
						{
							// ordering is correct, insert at this point
							packet->next = previousPacket->next;
							previousPacket->next = packet;
							packet->prev = previousPacket;
							
							if(previousPacket == lastPacketOfPacketGroup)
							{
								lastPacketOfPacketGroup = packet;
							}
							
							break;
						}
						else if(sequenceNumber == previousSequenceNumber)
						{
							break;
						}
						
						if(previousPacket == firstPacketOfPacketGroup)
						{
							// inserting this packet at the beginning of
							// the packet group
							packet->next = previousPacket;
							previousPacket->prev = packet;
							firstPacketOfPacketGroup = packet;
							break;
						}
						
						previousPacket = previousPacket->prev;
						
					} while(TRUE);
				}
				else
				{
					firstPacketOfPacketGroup = packet;
					lastPacketOfPacketGroup = packet;
				}
			}
			
			/////////////////////////////////////////////////////////
			// checking whether the packet group is complete or not
			/////////////////////////////////////////////////////////
			BOOL packetGroupIsComplete = FALSE;
			
			WORD expectedSequenceNumber = firstSeqNrOfPacketGroup;
			XMRTPPacket *thePacket = firstPacketOfPacketGroup;
			
			BOOL isFirstPacket = FALSE;
			
			if(expectedSequenceNumber == thePacket->GetSequenceNumber())
			{
				isFirstPacket = TRUE;
			}
			else
			{
				// the sequence number is not the expected one. Try to analyze
				// the bitstream to determine whether this is the first packet
				// of a packet group or not
				switch(codecIdentifier)
				{
					case XMCodecIdentifier_H261:
						isFirstPacket = IsFirstPacketOfH261Frame(thePacket);
						break;
					default:
						break;
				}
			}
			if(isFirstPacket == TRUE)
			{
				expectedSequenceNumber = thePacket->GetSequenceNumber();
				
				do {
					if(expectedSequenceNumber != thePacket->GetSequenceNumber())
					{
						break;
					}
					
					expectedSequenceNumber++;
					
					if(thePacket->next == NULL)
					{
						// no more packets in the packet group.
						// If the marker bit is set, we're complete
						if(thePacket->GetMarker() == TRUE)
						{
							packetGroupIsComplete = TRUE;
						}
						break;
					}
					
					thePacket = thePacket->next;
					
				} while(TRUE);
			}
			
			/////////////////////////////////////////////////////
			// If the packet group is complete, copy the packets
			// into a frame and send it to the XMMediaReceiver
			// system.
			/////////////////////////////////////////////////////
			
			if(packetGroupIsComplete == TRUE)
			{
				BOOL result = TRUE;
				PINDEX frameBufferSize = 0;
				
				switch(codecIdentifier)
				{
					case XMCodecIdentifier_H261:
						result = CopyH261PacketsIntoFrameBuffer(firstPacketOfPacketGroup, frameBuffer, &frameBufferSize);
						break;
					default:
						break;
				}
				
				if(result == TRUE)
				{
					result = _XMProcessFrame(sessionID, frameBuffer, frameBufferSize);
					if(result == FALSE)
					{
						processingSuccesful = FALSE;
					}
				}
				else
				{
					processingSuccesful = FALSE;
				}
				firstSeqNrOfPacketGroup = lastPacketOfPacketGroup->GetSequenceNumber() + 1;
				firstPacketOfPacketGroup = NULL;
				lastPacketOfPacketGroup = NULL;
				
				// Release all packets in the pool
				numberOfPacketsToRelease = packetIndex + 1;
			}
			
			if(processingSuccesful == FALSE)
			{
				cout << "Issuing update command" << endl;
				IssueVideoUpdatePictureCommand();
			}
			
			// Of not all packets can be released, the remaining packets are
			// put at the beginning of the packet pool.
			if(numberOfPacketsToRelease != 0)
			{
				unsigned i;
				for(i = 0; i < (packetIndex + 1 - numberOfPacketsToRelease); i++)
				{
					// swapping the remaining frames
					XMRTPPacket *packet = packets[i];
					packets[i] = packets[i + numberOfPacketsToRelease];
					packets[i + numberOfPacketsToRelease] = packet;
				}
				packetIndex = packetIndex + 1 - numberOfPacketsToRelease;
			}
			else
			{
				// increment the packetIndex, allocate a new XMRTPPacket if needed.
				// Also increase the size of the packet pool if required
				packetIndex++;
				if(packetIndex == allocatedPackets)
				{
					if(allocatedPackets % XM_PACKET_POOL_GRANULARITY == 0)
					{
						packets = (XMRTPPacket **)realloc(packets, (allocatedPackets + XM_PACKET_POOL_GRANULARITY) * sizeof(XMRTPPacket *));
					}
					
					packets[packetIndex] = new XMRTPPacket(source.GetDataSize());
					allocatedPackets++;
				}
			}
			
			// check for loop termination conditions
			PINDEX len = sinks.GetSize();
		
			inUse.Signal();

			if(len == 0)
			{
				break;
			}
			
		} while(source.ReadPacket(*(packets[packetIndex])) == TRUE);
		
		// End the media processing
		_XMStopMediaReceiving(sessionID);
	}
	
	// release the used RTP_DataFrames
	for(unsigned i = 0; i < allocatedPackets; i++)
	{
		XMRTPPacket *dataFrame = packets[i];
		delete dataFrame;
	}
	free(packets);
	free(frameBuffer);
}

void XMReceiverMediaPatch::SetCommandNotifier(const PNotifier & theNotifier,
											  BOOL fromSink)
{
	if(fromSink == FALSE)
	{
		notifier = theNotifier;
		notifierSet = TRUE;
	}
	OpalMediaPatch::SetCommandNotifier(theNotifier, fromSink);
}

void XMReceiverMediaPatch::IssueVideoUpdatePictureCommand()
{
	OpalVideoUpdatePicture command = OpalVideoUpdatePicture(-1, -1, -1);
	
	if(notifierSet == TRUE)
	{
		notifier(command, 0);
	}
}

BOOL XMReceiverMediaPatch::IsFirstPacketOfH261Frame(XMRTPPacket *packet)
{
	BYTE *data = packet->GetPayloadPtr();
	unsigned sbit = (data[0] >> 5) & 0x07;
	
	if((sbit == 0 && data[4] == 0 && data[5] == 1) ||
	   (sbit != 0 && data[4] == 0 && data[5] == 0))
	{
		return TRUE;
	}
	
	return FALSE;
}

BOOL XMReceiverMediaPatch::CopyH261PacketsIntoFrameBuffer(XMRTPPacket *packetListHead, BYTE *frameBuffer, PINDEX *frameBufferSize)
{
	XMRTPPacket *packet = packetListHead;
	unsigned bufferSize = 0;
	
	unsigned ebit;
	
	do {
		
		BYTE *dest = &(frameBuffer[bufferSize]);
		BYTE *payload = packet->GetPayloadPtr();
		PINDEX size = packet->GetPayloadSize();
		ebit = (payload[0] >> 2) & 0x07;
		
		// dropping the H.261 header
		payload += 4;
		size -= 4;
		
		memcpy(dest, payload, size);
		
		bufferSize += size;
		
		packet = packet->next;
		
		if(packet == NULL)
		{
			break;
		}
		
		if(ebit != 0)
		{
			bufferSize -= 1;
		}
		
	} while(TRUE);
	
	// adding a PSC to the end of the stream so that the codec does render the frame
	frameBuffer[bufferSize] = 0;
	frameBuffer[bufferSize+1] = (1 << ebit);
	frameBuffer[bufferSize+2] = 0;

	bufferSize += 3;
	
	*frameBufferSize = bufferSize;
	
	return TRUE;
}