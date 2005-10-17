/*
 * $Id: XMMediaStream.cpp,v 1.3 2005/10/17 12:57:53 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMMediaStream.h"
#include "XMTransmitterMediaPatch.h"

XMMediaStream::XMMediaStream(const OpalMediaFormat & mediaFormat,
										   unsigned sessionID,
										   BOOL isSource)
: OpalMediaStream(mediaFormat, sessionID, isSource)
{
}

XMMediaStream::~XMMediaStream()
{
}

BOOL XMMediaStream::ReadPacket(RTP_DataFrame & packet)
{	
	if(IsSink())
	{
		return FALSE;
	}
	
	// do nothing here, should never be called
	return TRUE;
}

BOOL XMMediaStream::WritePacket(RTP_DataFrame & packet)
{
	if(IsSource())
	{
		return FALSE;
	}
	
	// do nothing here, should never be called
	return TRUE;
}

BOOL XMMediaStream::IsSynchronous() const
{
	return FALSE;
}

BOOL XMMediaStream::Close()
{	
	if(IsSink())
	{
		return OpalMediaStream::Close();
	}
	
	if(!isOpen)
	{
		return FALSE;
	}
	
	patchMutex.Wait();
	
	if(patchThread != NULL)
	{
		if(PIsDescendant(patchThread, XMTransmitterMediaPatch))
		{
			XMTransmitterMediaPatch *mediaPatch = (XMTransmitterMediaPatch *)patchThread;
			patchThread = NULL;
			
			mediaPatch->Close();
			delete mediaPatch;
		}
		else
		{
			OpalMediaPatch *mediaPatch = patchThread;
			patchThread = NULL;
			
			mediaPatch->Close();
			delete mediaPatch;
		}
	}
	
	patchMutex.Signal();
	
	isOpen = FALSE;
	return TRUE;
}

BOOL XMMediaStream::ExecuteCommand(const OpalMediaCommand & command)
{
	cout << "OpalMediaStream executeCommand: " << command << endl;
	return TRUE;
}