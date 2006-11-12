/*
 * $Id: XMSIPEndPoint.h,v 1.7 2006/11/12 20:25:32 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_END_POINT_H__
#define __XM_SIP_END_POINT_H__

#include <ptlib.h>
#include <sip/sipcon.h>
#include <sip/sipep.h>

#include "XMTypes.h"

class XMSIPOptions;

class XMSIPRegistrarRecord : public PObject
{
	PCLASSINFO(XMSIPRegistrarRecord, PObject);
	
public:
	
	XMSIPRegistrarRecord(const PString & host,
						 const PString & username,
						 const PString & authorizationUsername,
						 const PString & password);
	~XMSIPRegistrarRecord();
	
	const PString & GetHost() const;
	const PString & GetUsername() const;
	const PString & GetAuthorizationUsername() const;
	const PString & GetPassword() const;
	void SetPassword(const PString & password);
	unsigned GetStatus() const;
	void SetStatus(unsigned status);
	
private:
		
	PString host;
	PString username;
	PString authorizationUsername;
	PString password;
	unsigned status;
};

class XMSIPEndPoint : public SIPEndPoint
{
	PCLASSINFO(XMSIPEndPoint, SIPEndPoint);
	
public:
	XMSIPEndPoint(OpalManager & manager);
	virtual ~XMSIPEndPoint();
	
	BOOL EnableListeners(BOOL enable);
	BOOL IsListening();
	
	void PrepareRegistrarSetup();
	void UseRegistrar(const PString & host,
					  const PString & username,
					  const PString & authorizationUsername,
					  const PString & password);
	void FinishRegistrarSetup();
	
	void UseProxy(const PString & hostname,
				  const PString & username,
				  const PString & password);
	
	void GetCallStatistics(XMCallStatisticsRecord *callStatistics);
	
	virtual void OnRegistrationFailed(const PString & host,
									  const PString & username,
									  SIP_PDU::StatusCodes reason,
									  BOOL wasRegistering);
	virtual void OnRegistered(const PString & host,
							  const PString & username,
							  BOOL wasRegistering);
	
	virtual void OnEstablished(OpalConnection & connection);
	virtual void OnReleased(OpalConnection & connection);
	
	virtual SIPConnection * CreateConnection(OpalCall & call,
											 const PString & token,
											 void * userData,
											 const SIPURL & destination,
											 OpalTransport * transport,
											 SIP_PDU * invite);
	
	// These methods are mostly copies of the existing methods
	// of the SIPEndPoint class. The main purpose is to establish the
	// following properties:
	// - Instead of sending out multiple REGISTER / INVITE to find out the
	//   correct interface to use, send OPTIONS requests first, freeze the
	//   interface and send the REGISTER / INVITEs afterwards. 
	// - Should the available interfaces change, re-REGISTER all registrations
	// - Should a refreshed REGISTER fail due to host not reachable, do a clean
    //   REGISTER refresh
	// - Ensure that a registration is refreshed before it expired. If the registration
	//   expired, do a clean refresh
	BOOL XMTransmitSIPInfo(SIP_PDU::Methods method, const PString & host,
						   const PString & username, const PString & authName = PString::Empty(),
						   const PString & password = PString::Empty(),
						   const PString & authRealm = PString::Empty(),
						   const PString & body = PString::Empty(),
						   int timeout = 0);
	OpalTransport * XMCreateTransport(const OpalTransportAddress & addr);
	static BOOL WriteSIPOptions(OpalTransport & transport, void * data);
	virtual void OnReceivedResponse(SIPTransaction & transaction, SIP_PDU & response);
	virtual void OnOptionsTimeout(XMSIPOptions *options);
	void RegistrationRefresh(PTimer &timer, INT value);
	
	virtual SIPURL GetDefaultRegisteredPartyName();
	
private:
	BOOL isListening;
	
	PString connectionToken;
	
	class XMSIPRegistrarList : public PList<XMSIPRegistrarRecord>
	{
	};
	
	PMutex registrarListMutex;
	XMSIPRegistrarList activeRegistrars;
	
	PMutex transportMutex;
	PMutex probingOptionsMutex;
	PSyncPoint probingSyncPoint;
	SIPTransactionDict probingOptions;
	BOOL probingSuccessful;
};

class XMSIPRegisterInfo : public SIPRegisterInfo
{
	PCLASSINFO(XMSIPRegisterInfo, SIPRegisterInfo);
	
public:
	XMSIPRegisterInfo(XMSIPEndPoint & ep, const PString & adjustedUsername, const PString & authName, 
					  const PString & password, int expire);
	~XMSIPRegisterInfo();
	
	virtual BOOL CreateTransport(OpalTransportAddress & addr);
	BOOL WillExpireWithinTimeInterval(PTimeInterval interval);
};

class XMSIPOptions : public SIPTransaction
{
	PCLASSINFO(XMSIPOptions, SIPTransaction);
	
public:
	XMSIPOptions(SIPEndPoint & ep, OpalTransport & trans, const SIPURL & address);
	~XMSIPOptions();
	
	BOOL Start();
	
	virtual void OnTimeout(PTimer & timer, INT value);
	
protected:
	virtual void SetTerminated(States newState);
};

#endif // __XM_SIP_END_POINT_H__
