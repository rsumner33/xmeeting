/*
 * $Id: XMMediaReceiver.m,v 1.20 2006/04/26 21:50:09 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMMediaReceiver.h"

#import "XMPrivate.h"
#import "XMUtils.h"
#import "XMVideoManager.h"
#import "XMCallbackBridge.h"

#define XM_PACKET_POOL_GRANULARITY 16
#define XM_CHUNK_BUFFER_SIZE 352*288*4

#define scanBit() \
mask >>= 1; \
if(mask == 0) { \
	dataIndex++; \
	mask = 0x80; \
}

#define readBit() \
bit = data[dataIndex] & mask; \
scanBit();

#define scanExpGolombSymbol() \
zero_counter = 0; \
readBit(); \
while(bit == 0) { \
	zero_counter++; \
	readBit(); \
} \
while(zero_counter != 0) { \
	zero_counter--; \
	scanBit(); \
}

#define readExpGolombSymbol() \
zero_counter = 0; \
readBit(); \
while(bit == 0) { \
	zero_counter++; \
	readBit(); \
} \
expGolombSymbol = (0x01 << zero_counter); \
while(zero_counter != 0) { \
	zero_counter--; \
	readBit(); \
	if(bit != 0) { \
		expGolombSymbol |= (0x01 << zero_counter); \
	} \
} \
expGolombSymbol -= 1;

@interface XMMediaReceiver (PrivateMethods)

- (UInt32)_getH264AVCCAtomLength;
- (XMVideoSize)_getH261VideoSize:(UInt8 *)frame length:(UInt32)length;
- (XMVideoSize)_getH263VideoSize:(UInt8 *)frame length:(UInt32)length;
- (XMVideoSize)_getH264VideoSize;
- (void)_createH264AVCCAtomInBuffer:(UInt8 *)buffer;

- (void)_releaseDecompressionSession;

@end

static void XMProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
										   OSStatus result,
										   ICMDecompressionTrackingFlags decompressionTrackingFlags,
										   CVPixelBufferRef pixelBuffer,
										   TimeValue64 displayTime,
										   TimeValue64 displayDuration,
										   ICMValidTimeFlags validTimeFlags,
										   void *reserved,
										   void *sourceFrameRefCon);

@implementation XMMediaReceiver

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{	
	self = [super init];
	
	videoDecompressionSession = NULL;
	videoCodecIdentifier = XMCodecIdentifier_UnknownCodec;
	
	return self;
}

- (void)_close
{
}

- (void)dealloc
{	
	[self _close];
	[super dealloc];
}

#pragma mark Data Handling Methods

- (void)_startMediaReceivingForSession:(unsigned)sessionID withCodec:(XMCodecIdentifier)codecIdentifier;
{
	ComponentResult err = noErr;
	
	err = EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
	if(err != noErr)
	{
		NSLog(@"EnterMoviesOnThread failed");
	}
	
	videoCodecIdentifier = codecIdentifier;
	
	if(codecIdentifier == XMCodecIdentifier_H264)
	{
		h264SPSAtoms = (XMAtom *)malloc(32 * sizeof(XMAtom));
		h264PPSAtoms = (XMAtom *)malloc(32 * sizeof(XMAtom));
		numberOfH264SPSAtoms = 0;
		numberOfH264PPSAtoms = 0;
	}
}

- (void)_stopMediaReceivingForSession:(unsigned)sessionID
{	
	[self _releaseDecompressionSession];
	
	[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingEnd)
													withObject:nil waitUntilDone:NO];
	ExitMoviesOnThread();
	
	if(videoCodecIdentifier == XMCodecIdentifier_H264)
	{
		unsigned i;
		
		for(i = 0; i < numberOfH264SPSAtoms; i++)
		{
			free(h264SPSAtoms[i].data);
		}
		
		free(h264SPSAtoms);
		
		for(i = 0; i < numberOfH264PPSAtoms; i++)
		{
			free(h264PPSAtoms[i].data);
		}
		
		free(h264PPSAtoms);
	}
}

- (BOOL)_decodeFrameForSession:(unsigned)sessionID data:(UInt8 *)data length:(unsigned)length
{
	ComponentResult err = noErr;
	
	if(videoDecompressionSession == NULL)
	{
		ImageDescriptionHandle imageDesc;
		NSSize videoDimensions;
		CodecType codecType;
		char *codecName;
		
		XMVideoSize videoMediaSize;
		
		switch(videoCodecIdentifier)
		{
			case XMCodecIdentifier_H261:
				codecType = kH261CodecType;
				codecName = "H.261";
				videoMediaSize = [self _getH261VideoSize:data length:length];
				break;
			case XMCodecIdentifier_H263:
				codecType = kH263CodecType;
				codecName = "H.263";
				videoMediaSize = [self _getH263VideoSize:data length:length];
				break;
			case XMCodecIdentifier_H264:
				codecType =  kH264CodecType;
				codecName = "H.264";
				if([self _getH264AVCCAtomLength] == 0)
				{
					NSLog(@"Can't create AVCC atom yet");
					return NO;
				}
				else
				{
					videoMediaSize = [self _getH264VideoSize];
				}
				break;
			default:
				NSLog(@"illegal codecType");
				return NO;
		}
		
		if(videoMediaSize == XMVideoSize_NoVideo)
		{
			NSLog(@"No valid data");
			return NO;
		}
		
		videoDimensions = XMGetVideoFrameDimensions(videoMediaSize);
		
		imageDesc = (ImageDescriptionHandle)NewHandleClear(sizeof(**imageDesc)+4);
		(**imageDesc).idSize = sizeof( **imageDesc)+4;
		(**imageDesc).cType = codecType;
		(**imageDesc).resvd1 = 0;
		(**imageDesc).resvd2 = 0;
		(**imageDesc).dataRefIndex = 0;
		(**imageDesc).version = 1;
		(**imageDesc).revisionLevel = 1;
		(**imageDesc).vendor = 'XMet';
		(**imageDesc).temporalQuality = codecNormalQuality;
		(**imageDesc).spatialQuality = codecNormalQuality;
		(**imageDesc).width = (short)videoDimensions.width;
		(**imageDesc).height = (short)videoDimensions.height;
		(**imageDesc).hRes = Long2Fix(72);
		(**imageDesc).vRes = Long2Fix(72);
		(**imageDesc).dataSize = 0;
		(**imageDesc).frameCount = 1;
		CopyCStringToPascal(codecName, (**imageDesc).name);
		(**imageDesc).depth = 24;
		(**imageDesc).clutID = -1;
		
		if(codecType == kH264CodecType)
		{
			UInt32 avccLength = [self _getH264AVCCAtomLength];
			
			Handle avccHandle = NewHandleClear(avccLength);
			[self _createH264AVCCAtomInBuffer:(UInt8 *)*avccHandle];
			
			err = AddImageDescriptionExtension(imageDesc, avccHandle, 'avcC');
			
			DisposeHandle(avccHandle);
		}
		
		ICMDecompressionSessionOptionsRef sessionOptions = NULL;
		err = ICMDecompressionSessionOptionsCreate(NULL, &sessionOptions);
		if(err != noErr)
		{
			NSLog(@"DecompressionSessionOptionsCreate  failed %d", (int)err);
		}
		
		ICMDecompressionTrackingCallbackRecord trackingCallbackRecord;
		
		trackingCallbackRecord.decompressionTrackingCallback = XMProcessDecompressedFrameProc;
		trackingCallbackRecord.decompressionTrackingRefCon = (void *)self;
		
		NSMutableDictionary *pixelBufferAttributes = [[NSMutableDictionary alloc] initWithCapacity:3];
		NSNumber *number;
		
		number = [[NSNumber alloc] initWithInt:(int)videoDimensions.width];
		[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferWidthKey];
		[number release];
		
		number = [[NSNumber alloc] initWithInt:(int)videoDimensions.height];
		[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferHeightKey];
		[number release];
		
		number = [[NSNumber alloc] initWithInt:k32ARGBPixelFormat];
		[pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
		[number release];
		
		err = ICMDecompressionSessionCreate(NULL, imageDesc, sessionOptions,
											(CFDictionaryRef)pixelBufferAttributes,
											&trackingCallbackRecord, &videoDecompressionSession);
		if(err != noErr)
		{
			NSLog(@"Creating of the decompressionSession failed %d", (int)err);
		}
		
		[pixelBufferAttributes release];
		ICMDecompressionSessionOptionsRelease(sessionOptions);
		
		DisposeHandle((Handle)imageDesc);
		
		number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)videoMediaSize];
		[_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoReceivingStart:)
														withObject:number waitUntilDone:NO];
		[number release];
		
		// Informing the application that we've started sending a certain codec. This is done here since
		// in case of H.264, the size has to be extracted from the SPS atom.
		_XMHandleVideoStreamOpened(0, codecName, videoMediaSize, true);
	}
	err = ICMDecompressionSessionDecodeFrame(videoDecompressionSession,
											 data, length,
											 NULL, NULL,
											 (void *)self);
	if(err != noErr)
	{
		
		NSLog(@"Decompression of the frame failed %d", (int)err);
		if(err == qErr)
		{
			[self _releaseDecompressionSession];
		}
		return NO;
	}
	return YES;
}

- (void)_handleH264SPSAtomData:(UInt8 *)data length:(unsigned)length
{
	// Check whether this atom is already stored
	BOOL atomFound = NO;
	unsigned i;
	for(i = 0; i < numberOfH264SPSAtoms; i++)
	{
		UInt16 atomLength = h264SPSAtoms[i].length;
		UInt8 *atomData = h264SPSAtoms[i].data;
		BOOL isSameAtom = YES;
		
		if(atomLength == length)
		{
			unsigned j;
			for(j = 0; j < length; j++)
			{
				if(atomData[j] != data[j])
				{
					isSameAtom = NO;
					break;
				}
			}
		}
		
		if(isSameAtom == YES)
		{
			atomFound = YES;
			break;
		}
	}
	
	if(atomFound == NO)
	{
		UInt8 *atomData = (UInt8 *)malloc(length * sizeof(UInt8));
		memcpy(atomData, data, length);
		h264SPSAtoms[numberOfH264SPSAtoms].length = length;
		h264SPSAtoms[numberOfH264SPSAtoms].data = atomData;
		numberOfH264SPSAtoms++;
	}
}

- (void)_handleH264PPSAtomData:(UInt8 *)data length:(unsigned)length
{
	// Check whether this atom is already stored
	BOOL atomFound = NO;
	unsigned i;
	for(i = 0; i < numberOfH264PPSAtoms; i++)
	{
		UInt16 atomLength = h264PPSAtoms[i].length;
		UInt8 *atomData = h264PPSAtoms[i].data;
		BOOL isSameAtom = YES;
		
		if(atomLength == length)
		{
			unsigned j;
			for(j = 0; j < length; j++)
			{
				if(atomData[j] != data[j])
				{
					isSameAtom = NO;
					break;
				}
			}
		}
		
		if(isSameAtom == YES)
		{
			atomFound = YES;
			break;
		}
	}
	
	if(atomFound == NO)
	{
		UInt8 *atomData = (UInt8 *)malloc(length * sizeof(UInt8));
		memcpy(atomData, data, length);
		h264PPSAtoms[numberOfH264PPSAtoms].length = length;
		h264PPSAtoms[numberOfH264PPSAtoms].data = atomData;
		numberOfH264PPSAtoms++;
	}
}

- (UInt32)_getH264AVCCAtomLength
{
	if(numberOfH264SPSAtoms == 0 || numberOfH264PPSAtoms == 0)
	{
		return 0;
	}
	
	// 1 Byte for configurationVersion, AVCProfileIndication,
	// profile_compatibility, AVCLevelIndication, lengthSizeMinusOne,
	// numOfSequenceParameterSets, numOfPictureParameterSets each.
	unsigned avccLength = 7;
	
	unsigned i;
	//for(i = 0; i < numberOfH264SPSAtoms; i++)
	for(i = 0; i < 1; i++)
	{
		// two bytes for the length of the SPS Atom
		avccLength += 2;
		
		avccLength += h264SPSAtoms[i].length;
	}
	//for(i = 0; i < numberOfH264PPSAtoms; i++)
	for(i = 0; i < 1; i++)
	{
		// two bytes for the length of the PPS Atom
		avccLength += 2;
		
		avccLength += h264PPSAtoms[i].length;
	}
	
	return avccLength;
}

- (XMVideoSize)_getH261VideoSize:(UInt8 *)frame length:(UInt32)length;
{
	printf("Determining H.261 size: %x %x %x %x %x\n", frame[0], frame[1], frame[2], frame[3], frame[4]);
	UInt8 *data = frame;
	UInt32 dataIndex = 0;
	UInt8 mask = 0x80;
	UInt8 bit;
	
	if(length < 4)
	{
		return XMVideoSize_NoVideo;
	}
	
	if(frame[0] == 0 &&
	   frame[1] == 0 &&
	   frame[2] == 0 &&
	   frame[3] == 0)
	{
		return XMVideoSize_NoVideo;
	}
	
	// determining the PSC location
	readBit();
	while(bit == 0)
	{
		readBit();
	}
	
	// check whether it is PSC
	readBit();
	if(bit != 0)
	{
		return XMVideoSize_NoVideo;
	}
	readBit();
	if(bit != 0)
	{
		return XMVideoSize_NoVideo;
	}
	readBit();
	if(bit != 0)
	{
		return XMVideoSize_NoVideo;
	}
	readBit();
	if(bit != 0)
	{
		return XMVideoSize_NoVideo;
	}
	
	// scanning past TR, SplitScreenIndicator, DocumentCameraIndicator, FreezePictureRelease
	dataIndex++;

	readBit();
	if(bit == 0)
	{
		printf("Is QCIF\n");
		return XMVideoSize_QCIF;
	}
	else
	{
		printf("Is CIF\n");
		return XMVideoSize_CIF;
	}
}

- (XMVideoSize)_getH263VideoSize:(UInt8 *)frame length:(UInt32)length
{	
	if(length < 5)
	{
		return XMVideoSize_NoVideo;
	}
	
	if(frame[0] == 0 &&
	   frame[1] == 0 &&
	   frame[2] == 0 &&
	   frame[3] == 0 &&
	   frame[4] == 0)
	{
		return XMVideoSize_NoVideo;
	}
	
	if(frame[0] != 0 ||
	   frame[1] != 0)
	{
		return XMVideoSize_NoVideo;
	}
	
	UInt8 *data = frame;
	UInt32 dataIndex = 2;
	UInt8 mask = 0x80;
	UInt8 bit;
	
	do {
		readBit();
	} while(bit == 0);
	
	dataIndex += 2;
	scanBit();
	scanBit();
	
	UInt8 size = 0;
	readBit();
	if(bit)
	{
		size |= 0x04;
	}
	readBit();
	if(bit)
	{
		size |= 0x02;
	}
	readBit();
	if(bit)
	{
		size |= 0x01;
	}
	
	if(size == 1)
	{
		return XMVideoSize_SQCIF;
	}
	else if(size == 2)
	{
		return XMVideoSize_QCIF;
	}
	else if(size == 3)
	{
		return XMVideoSize_CIF;
	}
	else
	{
		NSLog(@"UNKNOWN H.263 size");
		return XMVideoSize_NoVideo;
	}
}

- (XMVideoSize)_getH264VideoSize
{
	if(numberOfH264SPSAtoms == 0)
	{
		return XMVideoSize_NoVideo;
	}
	
	const UInt8 *data = h264SPSAtoms[0].data;
	UInt32 dataIndex;
	UInt8 mask;
	UInt8 bit;
	UInt8 zero_counter;
	UInt8 expGolombSymbol;
		
	// starting at byte 5 since the four first bytes are fixed-size
	dataIndex = 4;
	mask = 0x80;
	
	// scanning past seq_parameter_set_id
	scanExpGolombSymbol();
	
	// scanning past log2_max_frame_num_minus_4
	scanExpGolombSymbol();
	//readExpGolombSymbol();
	
	//reading pic_order_cnt_type
	readExpGolombSymbol();
	
	if(expGolombSymbol == 0)
	{
		// scanning past log2_max_pic_order_cnt_lsb_minus4
		scanExpGolombSymbol();
	}
	else if(expGolombSymbol == 1)
	{
		printf("pic_order_cnt_type is one\n");
		// scanning past delta_pic_order_always_zero_flag
		scanBit();
		
		// scanning past offset_for_non_ref_pic
		scanExpGolombSymbol();
		
		// scanning past offset_for_top_to_bottom_field
		scanExpGolombSymbol();
		
		// reading num_ref_frames_in_pic_order_cnt_cycle
		readExpGolombSymbol();
		
		UInt32 i;
		for(i = 0; i < expGolombSymbol; i++)
		{
			// scanning past offset_for_ref_frame[i]
			scanExpGolombSymbol();
		}
	}
	
	// scanning past num_ref_frames
	scanExpGolombSymbol();
	
	// scanning past gaps_in_frame_num_value_allowed_flag
	scanBit();
	
	// reading pic_width_in_mbs_minus1
	readExpGolombSymbol();
	UInt8 picWidthMinus1 = expGolombSymbol;
	
	// reading pic_height_in_mbs_minus1
	readExpGolombSymbol();
	UInt8 picHeightMinus1 = expGolombSymbol;
	
	if(picWidthMinus1 == 21 && picHeightMinus1 == 17)
	{
		return XMVideoSize_CIF;
	}
	else if(picWidthMinus1 == 10 && picHeightMinus1 == 8)
	{
		return XMVideoSize_QCIF;
	}
	else if(picWidthMinus1 == 19 && picHeightMinus1 == 14)
	{
		return XMVideoSize_320_240;
	}
	
	printf("UNKNOWN H.264 Size\n");
	// Return CIF to have at least a valid dimension
	return XMVideoSize_CIF;
}

- (void)_createH264AVCCAtomInBuffer:(UInt8 *)buffer
{	
	// Get the required information from the first SPS Atom
	UInt8 *spsAtom = h264SPSAtoms[0].data;
	UInt8 profile = spsAtom[1];
	UInt8 compatibility = spsAtom[2];
	UInt8 level = spsAtom[3];
	
	
	// configurationVersion is 1
	buffer[0] = 1;
	
	// setting the profile indication
	buffer[1] = profile;
	
	// setting the compatibility indication
	buffer[2] = compatibility;
	
	// setting the level indication
	buffer[3] = level;
	
	// lengthSizeMinusOne is 3 (4 bytes length)
	buffer[4] = 0xff;
	
	// There is only ever one SPS atom, or QuickTime will not
	// understand the AVCC structure
	buffer[5] = 1;
	
	unsigned index = 6;
	
	UInt16 length = h264SPSAtoms[0].length;
	UInt8 *data = h264SPSAtoms[0].data;
		
	buffer[index] = (UInt8)(length >> 8);
	buffer[index+1] = (UInt8)(length & 0x00ff);
		
	index += 2;
		
	UInt8 *dest = &(buffer[index]);
	memcpy(dest, data, length);
		
	index += length;
	
	// There is only ever one PPS atom, or QuickTime will not
	// understand the AVCC structure
	buffer[index] = 1;
	index++;
	
	length = h264PPSAtoms[0].length;
	data = h264PPSAtoms[0].data;
		
	buffer[index] = (UInt8)(length >> 8);
	buffer[index+1] = (UInt8)(length & 0x00ff);
		
	index += 2;
	
	dest = &(buffer[index]);
	memcpy(dest, data, length);
	
	index += length;
	
	printf("********\nReceived SPS and PPS Atoms:\n");
	unsigned i;
	for(i = 0; i < numberOfH264SPSAtoms; i++)
	{
		UInt8 *data = h264SPSAtoms[i].data;
		unsigned j;
		printf("SPS [%d]\n", i);
		for(j = 0; j < h264SPSAtoms[i].length; j++)
		{
			printf("%x ", data[j]);
		}
		printf("\n");
	}

	for(i = 0; i < numberOfH264PPSAtoms; i++)
	{
		UInt8 *data = h264PPSAtoms[i].data;
		unsigned j;
		printf("PPS [%d]\n", i);
		for(j = 0; j < h264PPSAtoms[i].length; j++)
		{
			printf("%x ", data[j]);
		}
		printf("\n");
	}
	printf("********\n");
	
	NSLog(@"Created AVCC Atom. There are %d SPS and %d PPS atoms to choose", numberOfH264SPSAtoms, numberOfH264PPSAtoms);
}

- (void)_releaseDecompressionSession
{
	if(videoDecompressionSession != NULL)
	{
		ICMDecompressionSessionRelease(videoDecompressionSession);
		videoDecompressionSession = NULL;
	}
}

@end

static void XMProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
										   OSStatus result,
										   ICMDecompressionTrackingFlags decompressionTrackingFlags,
										   CVPixelBufferRef pixelBuffer,
										   TimeValue64 displayTime,
										   TimeValue64 displayDuration,
										   ICMValidTimeFlags validTimeFlags,
										   void *reserved,
										   void *sourceFrameRefCon)
{
	if((kICMDecompressionTracking_EmittingFrame & decompressionTrackingFlags) && pixelBuffer != NULL)
	{
		[_XMVideoManagerSharedInstance _handleRemoteVideoFrame:pixelBuffer];
	}
}
