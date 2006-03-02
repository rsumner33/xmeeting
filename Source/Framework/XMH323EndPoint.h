/*
 * $Id: XMH323EndPoint.h,v 1.10 2006/03/02 22:35:54 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_END_POINT_H__
#define __XM_H323_END_POINT_H__

#include <ptlib.h>
#include <h323/h323ep.h>

#include "XMTypes.h"

class XMH323EndPoint : public H323EndPoint
{
	PCLASSINFO(XMH323EndPoint, H323EndPoint);

public:
	XMH323EndPoint(OpalManager & manager);
	virtual ~XMH323EndPoint();
	
	// Setup methods
	BOOL EnableListeners(BOOL flag);
	BOOL IsListening();
	XMGatekeeperRegistrationFailReason SetGatekeeper(const PString & address, const PString & identifier,
													 const PString & username, const PString & phoneNumber,
													 const PString & password);
	void CheckGatekeeperRegistration();
	
	// obtaining call statistics
	void GetCallStatistics(XMCallStatisticsRecord *callStatistics);
	
	// overriding some callbacks
	virtual void OnRegistrationConfirm();
	virtual void OnRegistrationReject();
	
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnReleased(OpalConnection & connection);
	
	virtual H323Connection * CreateConnection(OpalCall & call,
											  const PString & token,
											  void * userData,
											  OpalTransport & transport,
											  const PString & alias,
											  const H323TransportAddress & address,
											  H323SignalPDU * setupPDU);
	
private:
	BOOL isListening;
	BOOL didRegisterAtGatekeeper;
	XMGatekeeperRegistrationFailReason gatekeeperRegistrationFailReason;
	
	PString connectionToken;
};

#endif // __XM_H323_END_POINT_H__