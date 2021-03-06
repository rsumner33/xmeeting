/*
 * $Id: XMReceiverMediaPatch.h,v 1.14 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_RECEIVER_MEDIA_PATCH__
#define __XM_RECEIVER_MEDIA_PATCH__

#include <ptlib.h>
#include <opal/patch.h>

#include "XMRTPPacket.h"
#include "XMPacketReassemblers.h"

class XMReceiverMediaPatch : public OpalMediaPatch
{
  PCLASSINFO(XMReceiverMediaPatch, OpalMediaPatch);
	
public:
  XMReceiverMediaPatch(OpalMediaStream & source);
  ~XMReceiverMediaPatch();
	
  virtual void Start();
  virtual void SetCommandNotifier(const PNotifier & notifier, bool fromSink);
  
  void SetDecodingFailureNotifier(const PNotifier & notifier);
	
protected:
		
  // Overrides from OpalMediaPatch
  virtual void Main();
	
private:
		
  void IssueVideoUpdatePictureCommand();
  void HandleDecodingFailed();
	
  XMRTPPacketReassembler * packetReassembler;
  PNotifier commandNotifier;
  PNotifier decodingFailureNotifier;
};

#endif // __XM_RECEIVER_MEDIA_PATCH__

