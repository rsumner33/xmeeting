/*
 * $Id: XMOpalDispatcher.h,v 1.11 2006/06/06 16:38:48 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_OPAL_DISPATCHER_H__
#define __XM_OPAL_DISPATCHER_H__

#import <Foundation/Foundation.h>

#import "XMTypes.h"
#import "XMPreferences.h"

/**
 * Interface to Worker thread that dispatches commands to the OPAL subsystem
 **/
@interface XMOpalDispatcher : NSObject {

	NSPort *receivePort;
	
	unsigned callID;
	
	NSTimer *gatekeeperRegistrationCheckTimer;
	
	NSTimer *callStatisticsUpdateIntervalTimer;
	
	NSLock *sipRegistrationWaitLock;
	
}

+ (void)_setPreferences:(XMPreferences *)preferences externalAddress:(NSString *)externalAddress;
+ (void)_retryEnableH323:(XMPreferences *)preferences;
+ (void)_retryGatekeeperRegistration:(XMPreferences *)preferences;
+ (void)_retryEnableSIP:(XMPreferences *)preferences;
+ (void)_retrySIPRegistrations:(XMPreferences *)preferences;

+ (void)_initiateCallToAddress:(NSString *)address protocol:(XMCallProtocol)protocol;
+ (void)_initiateSpecificCallToAddress:(NSString *)address 
							  protocol:(XMCallProtocol)protocol
						   preferences:(XMPreferences *)preferences 
					   externalAddress:(NSString *)externalAddress;
+ (void)_callIsAlerting:(unsigned)callID;
+ (void)_incomingCall:(unsigned)callID
			 protocol:(XMCallProtocol)callProtocol
		   remoteName:(NSString *)remoteName
		 remoteNumber:(NSString *)remoteNumber
		remoteAddress:(NSString *)remoteAddress
	remoteApplication:(NSString *)remoteApplication;
+ (void)_acceptIncomingCall:(unsigned)callID;
+ (void)_rejectIncomingCall:(unsigned)callID;
+ (void)_callEstablished:(unsigned)callID incoming:(BOOL)isIncomingCall;
+ (void)_clearCall:(unsigned)callID;
+ (void)_callCleared:(unsigned)callID reason:(XMCallEndReason)callEndReason;

+ (void)_audioStreamOpened:(unsigned)callID 
					 codec:(NSString *)codec
				  incoming:(BOOL)isIncomingStream;
+ (void)_videoStreamOpened:(unsigned)callID 
					 codec:(NSString *)codec 
					  size:(XMVideoSize)videoSize
				  incoming:(BOOL)isIncomingStream;

+ (void)_audioStreamClosed:(unsigned)callID
				  incoming:(BOOL)isIncomingStream;
+ (void)_videoStreamClosed:(unsigned)callID 
				  incoming:(BOOL)isIncomingStream;

+ (void)_sendUserInputToneForCall:(unsigned)callID
							 tone:(char)tone;
+ (void)_sendUserInputStringForCall:(unsigned)callID
							 string:(NSString *)string;
+ (void)_startCameraEventForCall:(unsigned)callID 
						   event:(XMCameraEvent)event;
+ (void)_stopCameraEventForCall:(unsigned)callID;

- (id)_init;
- (void)_close;

- (void)_runOpalDispatcherThread:(NSString *)pTracePath;

	// called every time the STUN information is updated
- (void)_handleNATType:(XMNATType)natType externalAddress:(NSString *)externalAddress;

	// called every time the Framework registers at a gatekeeper
	// called on the OpalDispatcherThread, therefore safe
- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName;

	// Called every time the Framework unregisters from a gatekeeper
	// Called on the OpalDispatcherThread, therefore safe
- (void)_handleGatekeeperUnregistration;

- (void)_handleSIPRegistrationForHost:(NSString *)host username:(NSString *)username;

- (void)_handleSIPUnregistrationForHost:(NSString *)host username:(NSString *)username;

- (void)_handleSIPRegistrationFailureForHost:(NSString *)host username:(NSString *)username failReason:(XMSIPStatusCode)failReason;

	// called every time the Framework completes SIP Registration
    // may be called on any thread
- (void)_handleRegistrarSetupCompleted;

@end

#endif // _XM_OPAL_DISPATCHER_H__
