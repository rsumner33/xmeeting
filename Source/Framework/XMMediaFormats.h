/*
 * $Id: XMMediaFormats.h,v 1.2 2005/10/12 21:07:40 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_MEDIA_FORMATS_H__
#define __XM_MEDIA_FORMATS_H__

#include <ptlib.h>
#include <opal/mediafmt.h>
#include <codec/vidcodec.h>
#include <h323/h323caps.h>

#include "XMTypes.h"

// definition of the "XMeeting" video formats

#define XM_VIDEO "XMVideo"
#define XM_H261_QCIF "H.261 (QCIF)"
#define XM_H261_CIF  "H.261 (CIF)"

extern const OpalVideoFormat & XMGetMediaFormat_Video();
extern const OpalVideoFormat & XMGetMediaFormat_H261_QCIF();
extern const OpalVideoFormat & XMGetMediaFormat_H261_CIF();

#define XM_MEDIA_FORMAT_VIDEO XMGetMediaFormat_Video()
#define XM_MEDIA_FORMAT_H261_QCIF XMGetMediaFormat_H261_QCIF()
#define XM_MEDIA_FORMAT_H261_CIF XMGetMediaFormat_H261_CIF()

// definition of the transcoders

class XM_H261_VIDEO_QCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H261_VIDEO_QCIF, OpalVideoTranscoder);
	
public:
	XM_H261_VIDEO_QCIF();
	~XM_H261_VIDEO_QCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_H261_VIDEO_CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_H261_VIDEO_CIF, OpalVideoTranscoder);
	
public:
	XM_H261_VIDEO_CIF();
	~XM_H261_VIDEO_CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H261_QCIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H261_QCIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H261_QCIF();
	~XM_VIDEO_H261_QCIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

class XM_VIDEO_H261_CIF : public OpalVideoTranscoder
{
	PCLASSINFO(XM_VIDEO_H261_CIF, OpalVideoTranscoder);
	
public:
	XM_VIDEO_H261_CIF();
	~XM_VIDEO_H261_CIF();
	virtual PINDEX GetOptimalDataFrameSize(BOOL input) const;
	virtual BOOL ConvertFrames(const RTP_DataFrame & src, RTP_DataFrameList & dst);
};

// H.323 Capability definitions

class XM_H323_H261_Capability : public H323VideoCapability
{
	PCLASSINFO(XM_H323_H261_Capability, H323VideoCapability);
	
public:
	XM_H323_H261_Capability(XMVideoSize videoSize);
	virtual PObject * Clone() const;
	Comparison Compare(const PObject & obj) const;
	virtual unsigned GetSubType() const;
	virtual PString GetFormatName() const;
	virtual BOOL OnSendingPDU(H245_VideoCapability & pdu) const;
	virtual BOOL OnSendingPDU(H245_VideoMode & pdu) const;
	virtual BOOL OnReceivedPDU(const H245_VideoCapability & pdu);
	
private:
	unsigned cifMPI;
	unsigned qcifMPI;
	BOOL temporalSpatialTradeOffCapability;
	unsigned maxBitRate;
	BOOL stillImageTransmission;
};

#define XM_REGISTER_H323_CAPABILITIES \
	H323_REGISTER_CAPABILITY_FUNCTION(XM_H323_H261_QCIF, XM_H261_QCIF, H323_NO_EP_VAR) \
		{ return new XM_H323_H261_Capability(XMVideoSize_QCIF); } \
	H323_REGISTER_CAPABILITY_FUNCTION(XM_H323_H261_CIF, XM_H261_CIF, H323_NO_EP_VAR) \
		{ return new XM_H323_H261_Capability(XMVideoSize_CIF); }

// macro for registering the media formats

#define XM_REGISTER_FORMATS() \
	XM_REGISTER_H323_CAPABILITIES \
	OPAL_REGISTER_TRANSCODER(XM_H261_VIDEO_CIF, XM_MEDIA_FORMAT_H261_CIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_H261_VIDEO_QCIF, XM_MEDIA_FORMAT_H261_QCIF, XM_MEDIA_FORMAT_VIDEO); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H261_CIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261_CIF); \
	OPAL_REGISTER_TRANSCODER(XM_VIDEO_H261_QCIF, XM_MEDIA_FORMAT_VIDEO, XM_MEDIA_FORMAT_H261_QCIF)

#endif // __XM_MEDIA_FORMATS_H__