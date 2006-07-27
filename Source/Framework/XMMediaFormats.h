/*
 * $Id: XMMediaFormats.h,v 1.15 2006/07/27 21:13:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_FORMATS_H__
#define __XM_MEDIA_FORMATS_H__

#include <ptlib.h>
#include <opal/mediafmt.h>
#include <codec/vidcodec.h>
#include <h323/h323caps.h>

#include "XMTypes.h"

class H245_H2250Capability;

#pragma mark Media Format Strings

// Audio Format Identifiers
// These identifiers shall be used to enable/disable/reorder media formats
extern const char *_XMMediaFormatIdentifier_G711_uLaw;
extern const char *_XMMediaFormatIdentifier_G711_ALaw;

// Video Format Identifiers
// These identifiers shall be used to enable/disable/reorder media formats
extern const char *_XMMediaFormatIdentifier_H261;
extern const char *_XMMediaFormatIdentifier_H263;
extern const char *_XMMediaFormatIdentifier_H264;

extern const char *_XMMediaFormat_Video;
extern const char *_XMMediaFormat_H261;
extern const char *_XMMediaFormat_H263;
extern const char *_XMMediaFormat_H263Plus;
extern const char *_XMMediaFormat_H264;

// Format Encodings
extern const char *_XMMediaFormatEncoding_H261;
extern const char *_XMMediaFormatEncoding_H263;
extern const char *_XMMediaFormatEncoding_H263Plus;
extern const char *_XMMediaFormatEncoding_H264;

#pragma mark XMeeting Video Formats

extern const OpalVideoFormat & XMGetMediaFormat_Video();
extern const OpalVideoFormat & XMGetMediaFormat_H261();
extern const OpalVideoFormat & XMGetMediaFormat_H263();
extern const OpalVideoFormat & XMGetMediaFormat_H263Plus();
extern const OpalVideoFormat & XMGetMediaFormat_H264();

#define XM_MEDIA_FORMAT_VIDEO XMGetMediaFormat_Video()
#define XM_MEDIA_FORMAT_H261 XMGetMediaFormat_H261()
#define XM_MEDIA_FORMAT_H263 XMGetMediaFormat_H263()
#define XM_MEDIA_FORMAT_H263PLUS XMGetMediaFormat_H263Plus()
#define XM_MEDIA_FORMAT_H264 XMGetMediaFormat_H264()

#pragma mark Constants

#define XM_H264_PROFILE_BASELINE 1
#define XM_H264_PROFILE_MAIN 2

#define XM_H264_LEVEL_1		1
#define XM_H264_LEVEL_1_B	2
#define XM_H264_LEVEL_1_1	3
#define XM_H264_LEVEL_1_2	4
#define XM_H264_LEVEL_1_3	5
#define XM_H264_LEVEL_2		6

#define XM_H264_PACKETIZATION_MODE_SINGLE_NAL 1
#define XM_H264_PACKETIZATION_MODE_NON_INTERLEAVED 2

#pragma mark -
#pragma mark managing MediaFormats

BOOL _XMIsVideoMediaFormat(const OpalMediaFormat & mediaFormat);
XMCodecIdentifier _XMGetMediaFormatCodec(const OpalMediaFormat & mediaFormat);
XMVideoSize _XMGetMediaFormatSize(const OpalMediaFormat & mediaFormat);
const char *_XMGetMediaFormatName(const OpalMediaFormat & mediaFormat);

#pragma mark -
#pragma mark Transcoder classes

class XMVideoTranscoder : public OpalVideoTranscoder
{
	PCLASSINFO(XMVideoTranscoder, OpalVideoTranscoder);
	
public:
	
	XMVideoTranscoder(const OpalVideoFormat & src, const OpalVideoFormat & dst);
	~XMVideoTranscoder();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
	
	RTP_DataFrame::PayloadMapType GetPayloadMap() const { return payloadTypeMap; }
};

class XM_H261_VIDEO : public XMVideoTranscoder
{
	PCLASSINFO(XM_H261_VIDEO, XMVideoTranscoder);
	
public:
	XM_H261_VIDEO();
	~XM_H261_VIDEO();
};

class XM_H263_VIDEO : public XMVideoTranscoder
{
	PCLASSINFO(XM_H263_VIDEO, XMVideoTranscoder);
public:
	XM_H263_VIDEO();
	~XM_H263_VIDEO();
};

class XM_H263PLUS_VIDEO : public XMVideoTranscoder
{
	PCLASSINFO(XM_H263PLUS_VIDEO, XMVideoTranscoder);
	
public:
	XM_H263PLUS_VIDEO();
	~XM_H263PLUS_VIDEO();
};

class XM_H264_VIDEO : public XMVideoTranscoder
{
	PCLASSINFO(XM_H264_VIDEO, XMVideoTranscoder);
public:
	XM_H264_VIDEO();
	~XM_H264_VIDEO();
};

class XM_VIDEO_H261 : public XMVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H261, XMVideoTranscoder);
	
public:
	XM_VIDEO_H261();
	~XM_VIDEO_H261();
};

class XM_VIDEO_H263 : public XMVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H263, XMVideoTranscoder);
	
public:
	XM_VIDEO_H263();
	~XM_VIDEO_H263();
};

class XM_VIDEO_H263PLUS : public XMVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H263PLUS, XMVideoTranscoder);
	
public:
	XM_VIDEO_H263PLUS();
	~XM_VIDEO_H263PLUS();
};

class XM_VIDEO_H264 : public XMVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H264, XMVideoTranscoder);
	
public:
	XM_VIDEO_H264();
	~XM_VIDEO_H264();
};

#pragma mark -
#pragma mark H.323 Capabilities

class XMH323VideoCapability : public H323VideoCapability
{
	PCLASSINFO(XMH323VideoCapability, H323VideoCapability);
	
public:
	virtual BOOL OnSendingTerminalCapabilitySet(H245_TerminalCapabilitySet & terminalCapabilitySet) const = 0;
	virtual BOOL OnReceivedTerminalCapabilitySet(const H245_H2250Capability & h2250Capability) = 0;
	virtual BOOL OnSendingPDU(H245_H2250LogicalChannelParameters & param) const = 0;
	virtual BOOL OnReceivedPDU(const H245_H2250LogicalChannelParameters & param) = 0;
	
	virtual BOOL IsValidCapabilityForSending() const = 0;
	virtual BOOL IsValidCapabilityForReceiving() const = 0;
	virtual Comparison CompareTo(const XMH323VideoCapability & obj) const = 0;
};

class XM_H323_H261_Capability : public XMH323VideoCapability
{
	PCLASSINFO(XM_H323_H261_Capability, XMH323VideoCapability);
	
public:
	XM_H323_H261_Capability();
	virtual PObject * Clone() const;
	virtual Comparison Compare(const PObject & obj) const;
	virtual unsigned GetSubType() const;
	virtual PString GetFormatName() const;
	virtual BOOL OnSendingPDU(H245_VideoCapability & pdu) const;
	virtual BOOL OnSendingPDU(H245_VideoMode & pdu) const;
	virtual BOOL OnReceivedPDU(const H245_VideoCapability & pdu);
	
	virtual BOOL OnSendingTerminalCapabilitySet(H245_TerminalCapabilitySet & terminalCapabilitySet) const;
	virtual BOOL OnReceivedTerminalCapabilitySet(const H245_H2250Capability & h2250Capability);
	virtual BOOL OnSendingPDU(H245_H2250LogicalChannelParameters & param) const;
	virtual BOOL OnReceivedPDU(const H245_H2250LogicalChannelParameters & param);
	
	virtual BOOL IsValidCapabilityForSending() const;
	virtual BOOL IsValidCapabilityForReceiving() const;
	virtual Comparison CompareTo(const XMH323VideoCapability & obj) const;
	
private:
	unsigned cifMPI;
	unsigned qcifMPI;
	unsigned maxBitRate;
};

class XM_H323_H263_Capability : public XMH323VideoCapability
{
	PCLASSINFO(XM_H323_H263_Capability, XMH323VideoCapability);
	
public:
	XM_H323_H263_Capability();
	XM_H323_H263_Capability(BOOL isH263PlusCapability);
	virtual PObject * Clone() const;
	virtual Comparison Compare(const PObject & obj) const;
	virtual unsigned GetSubType() const;
	virtual PString GetFormatName() const;
	virtual BOOL OnSendingPDU(H245_VideoCapability & pdu) const;
	virtual BOOL OnSendingPDU(H245_VideoMode & pdu) const;
	virtual BOOL OnReceivedPDU(const H245_VideoCapability & pdu);
	
	virtual BOOL OnSendingTerminalCapabilitySet(H245_TerminalCapabilitySet & terminalCapabilitySet) const;
	virtual BOOL OnReceivedTerminalCapabilitySet(const H245_H2250Capability & h2250Capability);
	virtual BOOL OnSendingPDU(H245_H2250LogicalChannelParameters & param) const;
	virtual BOOL OnReceivedPDU(const H245_H2250LogicalChannelParameters & param);
	
	virtual BOOL IsValidCapabilityForSending() const;
	virtual BOOL IsValidCapabilityForReceiving() const;
	virtual Comparison CompareTo(const XMH323VideoCapability & obj) const;
	
	BOOL IsH263PlusCapability() const;
	
private :
	unsigned sqcifMPI;
	unsigned qcifMPI;
	unsigned cifMPI;
	unsigned cif4MPI;
	unsigned cif16MPI;
	
	unsigned maxBitRate;
	
	unsigned slowSqcifMPI;
	unsigned slowQcifMPI;
	unsigned slowCifMPI;
	unsigned slowCif4MPI;
	unsigned slowCif16MPI;
	
	BOOL isH263PlusCapability;
};

class XM_H323_H263PLUS_Capability : public XM_H323_H263_Capability
{
	PCLASSINFO(XM_H323_H263PLUS_Capability, XM_H323_H263_Capability);
	
public:
	
	XM_H323_H263PLUS_Capability();
};

class XM_H323_H264_Capability : public XMH323VideoCapability
{
	PCLASSINFO(XM_H323_H264_Capability, XMH323VideoCapability);
	
public:
	XM_H323_H264_Capability();
	virtual PObject * Clone() const;
	virtual Comparison Compare(const PObject & obj) const;
	virtual unsigned GetSubType() const;
	virtual PString GetFormatName() const;
	virtual BOOL OnSendingPDU(H245_VideoCapability & pdu) const;
	virtual BOOL OnSendingPDU(H245_VideoMode & pdu) const;
	virtual BOOL OnReceivedPDU(const H245_VideoCapability & pdu);
	
	virtual BOOL OnSendingTerminalCapabilitySet(H245_TerminalCapabilitySet & terminalCapabilitySet) const;
	virtual BOOL OnReceivedTerminalCapabilitySet(const H245_H2250Capability & h2250Capability);
	virtual BOOL OnSendingPDU(H245_H2250LogicalChannelParameters & param) const;
	virtual BOOL OnReceivedPDU(const H245_H2250LogicalChannelParameters & param);
	
	virtual BOOL IsValidCapabilityForSending() const;
	virtual BOOL IsValidCapabilityForReceiving() const;
	virtual Comparison CompareTo(const XMH323VideoCapability & obj) const;
	
	unsigned GetProfile() const;
	unsigned GetLevel() const;
	
private:
	
	unsigned maxBitRate;
	WORD profile;
	unsigned level;
};

#pragma mark -
#pragma mark Packetization Functions

BOOL _XMIsReceivingRFC2429();
void _XMSetIsReceivingRFC2429(BOOL flag);
unsigned _XMGetH264Profile();
unsigned _XMGetH264Level();
unsigned _XMGetH264PacketizationMode();
void _XMSetH264EnableLimitedMode(BOOL flag);

#pragma mark -
#pragma mark SDP Functions

unsigned _XMGetMaxH261BitRate();
PString _XMGetFMTP_H261(unsigned maxBitRate = UINT_MAX, 
						XMVideoSize videoSize = XMVideoSize_NoVideo,
						unsigned mpi = 1);
void _XMParseFMTP_H261(const PString & fmtp, unsigned & maxBitRate, XMVideoSize & videoSize, unsigned & mpi);

unsigned _XMGetMaxH263BitRate();
PString _XMGetFMTP_H263(unsigned maxBitRate = UINT_MAX,
						XMVideoSize videoSize = XMVideoSize_NoVideo,
						unsigned mpi = 1);
void _XMParseFMTP_H263(const PString & fmtp, unsigned & maxBitRate, XMVideoSize & videoSize, unsigned & mpi);

unsigned _XMGetMaxH264BitRate();
PString _XMGetFMTP_H264(unsigned maxBitRate = UINT_MAX,
						XMVideoSize videoSize = XMVideoSize_NoVideo,
						unsigned mpi = 1);
void _XMParseFMTP_H264(const PString & fmtp, unsigned & maxBitRate, XMVideoSize & videoSize, unsigned & mpi);

#pragma mark -
#pragma mark Macros

#define XM_REGISTER_FORMATS() \
	static H323CapabilityFactory::Worker<XM_H323_H261_Capability> h261Factory(XM_MEDIA_FORMAT_H261, true); \
    static H323CapabilityFactory::Worker<XM_H323_H263_Capability> h263Factory(XM_MEDIA_FORMAT_H263, true); \
    static H323CapabilityFactory::Worker<XM_H323_H263PLUS_Capability> h263PlusFactory(XM_MEDIA_FORMAT_H263PLUS, true); \
    static H323CapabilityFactory::Worker<XM_H323_H264_Capability> h264Factory(XM_MEDIA_FORMAT_H264, true); \
	OPAL_REGISTER_TRANSCODER(XM_H261_VIDEO, XM_MEDIA_FORMAT_H261, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H263_VIDEO, XM_MEDIA_FORMAT_H263, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H263PLUS_VIDEO, XM_MEDIA_FORMAT_H263PLUS, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H264_VIDEO, XM_MEDIA_FORMAT_H264, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H261, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H263, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H263PLUS, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H263PLUS); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H264, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H264)

#endif // __XM_MEDIA_FORMATS_H__