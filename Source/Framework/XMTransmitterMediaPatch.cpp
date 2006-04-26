/*
 * $Id: XMTransmitterMediaPatch.cpp,v 1.17 2006/04/26 21:50:09 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include "XMTransmitterMediaPatch.h"

#include <math.h>
#include <opal/mediastrm.h>

#include "XMBridge.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"
#include "XMCallbackBridge.h"

static XMTransmitterMediaPatch *videoTransmitterPatch = NULL;

XMTransmitterMediaPatch::XMTransmitterMediaPatch(OpalMediaStream & src)
: OpalMediaPatch(src)
{
	doesRunOwnThread = TRUE;
	isTerminated = FALSE;
	dataFrame = NULL;
	codecIdentifier = XMCodecIdentifier_UnknownCodec;
}

XMTransmitterMediaPatch::~XMTransmitterMediaPatch()
{
}

BOOL XMTransmitterMediaPatch::IsTerminated() const
{
	if(doesRunOwnThread == TRUE)
	{
		return OpalMediaPatch::IsTerminated();
	}
	else
	{
		// since we don't run our own thread, the IsTerminated()
		// method must return whether the MediaTransmitter is still
		// transmitting media or not. This is required so that
		// WaitForTermination() does behave correctly
		return isTerminated;
	}
}

void XMTransmitterMediaPatch::Resume()
{
	//cout << "TRANSMITTER RESUME" << endl;
	if(PIsDescendant(&source, XMMediaStream))
	{
		// If Resume has already been called, don't start the process again
		if(doesRunOwnThread == FALSE)
		{
			return;
		}

		// we don't spawn a new thread but instead
		// tell the MediaTransmitter to start transmitting
		// the desired media
		doesRunOwnThread = FALSE;
		isTerminated = FALSE;
		videoTransmitterPatch = this;
		
		PINDEX i = sinks.GetSize();
		if(i > 0)
		{
			unsigned maxFramesPerSecond = UINT_MAX;
			unsigned maxBitrate = _XMGetVideoBandwidthLimit();
			
			OpalMediaFormat mediaFormat = sinks[0].stream->GetMediaFormat();
			payloadType = mediaFormat.GetPayloadType();
			payloadType = (RTP_DataFrame::PayloadTypes)34;
			
			unsigned frameTime = mediaFormat.GetFrameTime();
			unsigned framesPerSecond = (unsigned)round(90000.0 / (double)frameTime);
			unsigned bitrate = mediaFormat.GetBandwidth()*100;
			unsigned flags = 0;
			
			cout << "BITRATE: " << bitrate << endl;
						
			codecIdentifier = _XMGetMediaFormatCodec(mediaFormat);
			XMVideoSize videoSize = _XMGetMediaFormatSize(mediaFormat);

			if(codecIdentifier == XMCodecIdentifier_H263)
			{
				// If we're  sending H.263, we need to know which
				// format to send. The payload code is submitted in the
				// flags parameter
				flags = payloadType;
				
				if(payloadType == RTP_DataFrame::H263)
				{
					cout << "Sending RFC2190" << endl;
				}
				else
				{
					cout << "Sending RFC2429" << endl;
				}
			}
			else if(codecIdentifier == XMCodecIdentifier_H264)
			{
				if(_XMGetH264PacketizationMode() == XM_H264_PACKETIZATION_MODE_SINGLE_NAL)
				{
					// We send only at a limited bitrate to avoid too many
					// NAL units which are TOO big to fit
					if(bitrate > 320000)
					{
						bitrate = 320000;
					}
				}
				
				cout << "Sending H.264 with modes: " << _XMGetH264PacketizationMode() << " " << _XMGetH264Profile() << " " << _XMGetH264Level() << endl;
				flags = (_XMGetH264PacketizationMode() << 8) + (_XMGetH264Profile() << 4) + _XMGetH264Level();
			}
			
			// adjusting the maxFramesPerSecond / maxBitrate parameters
			if(framesPerSecond < maxFramesPerSecond)
			{
				maxFramesPerSecond = framesPerSecond;
			}
			
			if(bitrate < maxBitrate)
			{
				maxBitrate = bitrate;
			}
			
			if(codecIdentifier == XMCodecIdentifier_UnknownCodec ||
			   videoSize == XMVideoSize_NoVideo)
			{
				//cout << "Trying to open unknown codec for transmission" << endl;
				return;
			}
			
			_XMStartMediaTransmit(2, codecIdentifier, videoSize, maxFramesPerSecond, maxBitrate, flags);
		}
	}
	else
	{
		// behave as normally
		OpalMediaPatch::Resume();
	}
}

void XMTransmitterMediaPatch::Close()
{
	if(doesRunOwnThread == FALSE)
	{
		_XMStopMediaTransmit(2);
	}
	
	OpalMediaPatch::Close();
	
	// Waiting until the MediaTransmitter suspended the
	// transmission of media
	while(!IsTerminated())
	{
		Sleep(10);
	}
}

BOOL XMTransmitterMediaPatch::ExecuteCommand(const OpalMediaCommand & command,
											 BOOL fromSink)
{
	if(fromSink)
	{
		if(PIsDescendant(&command, OpalVideoUpdatePicture))
		{
			_XMUpdatePicture();
			return TRUE;
		}
		else if(PIsDescendant(&command, OpalTemporalSpatialTradeOff))
		{
			return TRUE;
		}
		else if(PIsDescendant(&command, OpalVideoFreezePicture))
		{
			return TRUE;
		}
	}
	
	return OpalMediaPatch::ExecuteCommand(command, fromSink);
}

void XMTransmitterMediaPatch::SetTimeStamp(unsigned sessionID, unsigned timeStamp)
{
	if(videoTransmitterPatch == NULL)
	{
		//cout << "No VideoTransmitterPatch found!" << endl;
		return;
	}
	
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	if(frame == NULL)
	{
		frame = new RTP_DataFrame(3000);
		videoTransmitterPatch->dataFrame = frame;
		frame->SetPayloadSize(0);
		
		//cout << "SETTING PAYLOAD TYPE FOR SENDING: " << videoTransmitterPatch->payloadType << endl;
		frame->SetPayloadType(videoTransmitterPatch->payloadType);
		cout << "SENDING PTYPE: " << videoTransmitterPatch->payloadType << endl;
		//frame->SetPayloadType((RTP_DataFrame::PayloadTypes)103);
		
		/*XMCodecIdentifier theCodec = videoTransmitterPatch->codecIdentifier;
		
		if(theCodec == XMCodecIdentifier_H261)
		{
			frame->SetPayloadType(RTP_DataFrame::H261);
		}
		else if(theCodec == XMCodecIdentifier_H263)
		{
			OpalMediaFormat mediaFormat = videoTransmitterPatch->sinks[0].stream->GetMediaFormat();
			RTP_DataFrame::PayloadTypes payloadType = h263PayloadType;
			frame->SetPayloadType(payloadType);
		}
		else if(theCodec == XMCodecIdentifier_H264)
		{
			frame->SetPayloadType(RTP_DataFrame::DynamicBase);
		}*/
	}
	
	frame->SetTimestamp(timeStamp);
}

void XMTransmitterMediaPatch::AppendData(unsigned sessionID,
										 void *data,
										 unsigned length)
{
	if(videoTransmitterPatch == NULL)
	{
		//cout << "No VideoTransmitterPatch found (3)" << endl;
		return;
	}
	
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	if(frame == NULL)
	{
		//cout << "FRAME IS NULL" << endl;
		return;
	}
	
	BYTE *dataPtr = frame->GetPayloadPtr();
	PINDEX dataSize = frame->GetPayloadSize();
	
	dataPtr += dataSize;
	dataSize += length;
	
	memcpy(dataPtr, data, length);
	
	frame->SetPayloadSize(dataSize);
}

void XMTransmitterMediaPatch::SendPacket(unsigned sessionID, BOOL setMarker)
{	
	if(videoTransmitterPatch == NULL)
	{
		//cout << "No VideoTransmitterPatch found (4)" << endl;
		return;
	}
		
	RTP_DataFrame *frame = videoTransmitterPatch->dataFrame;
	
	frame->SetMarker(setMarker);
	
	videoTransmitterPatch->inUse.Wait();
		
	videoTransmitterPatch->FilterFrame(*frame, videoTransmitterPatch->source.GetMediaFormat());
	
	PINDEX i;
	for(i = 0; i < videoTransmitterPatch->sinks.GetSize(); i++)
	{
		BOOL result = videoTransmitterPatch->sinks[i].stream->WritePacket(*frame);
		if(result == FALSE)
		{
			//cout << "ERROR Writing frame to sink!" << endl;
		}
	}
	
	videoTransmitterPatch->inUse.Signal();
	
	videoTransmitterPatch->dataFrame->SetPayloadSize(0);
}

void XMTransmitterMediaPatch::HandleDidStopTransmitting(unsigned sessionID)
{
	if(videoTransmitterPatch == NULL)
	{
		//cout << "ERROR: NO TRANSMITTER PATCH FOUND" << endl;
		return;
	}
	
	videoTransmitterPatch->isTerminated = TRUE;
	videoTransmitterPatch = NULL;
}