/*
 * $Id: XMConnection.h,v 1.1 2005/10/11 09:03:10 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CONNECTION_H__
#define __XM_CONNECTION_H__

#include <ptlib.h>
#include <opal/connection.h>
#include "XMBridge.h"

class XMEndPoint;

class XMConnection : public OpalConnection
{
	PCLASSINFO(XMConnection, OpalConnection);
	
public:
	XMConnection(OpalCall & call,
				 XMEndPoint & endPoint,
				 const PString & token);
	~XMConnection();
	
	virtual BOOL SetUpConnection();
	virtual BOOL SetAlerting(const PString & calleeName,
							 BOOL withMedia);
	virtual BOOL SetConnected();
	virtual OpalMediaFormatList GetMediaFormats() const;
	virtual OpalMediaStream * CreateMediaStream(const OpalMediaFormat & mediaFormat,
												unsigned sessionID,
												BOOL isSource);
	virtual BOOL OnOpenMediaStream(OpalMediaStream & stream);
	
	void InitiateCall();
	void AcceptIncoming();
	PSoundChannel * CreateSoundChannel(BOOL isSource);
	
	virtual BOOL IsMediaBypassPossible(unsigned sessionID) const;
	
	virtual BOOL OpenSourceMediaStream(const OpalMediaFormatList & mediaFormats,
									   unsigned sessionID);
	virtual OpalMediaStream * OpenSinkMediaStream(OpalMediaStream & source);
	virtual void StartMediaStreams();
	virtual void CloseMediaStreams();
	virtual void RemoveMediaStreams();
	
	virtual void OnClosedMediaStream(OpalMediaStream & stream);
	
private:
	XMEndPoint & endPoint;
};

#endif // __XM_CONNECTION_H__

