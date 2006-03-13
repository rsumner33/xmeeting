/*
 * $Id: XMOpalDispatcher.h,v 1.6 2006/03/13 23:46:23 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_OPAL_DISPATCHER_H__
#define __XM_OPAL_DISPATCHER_H__

#import <Foundation/Foundation.h>

#import "XMPreferences.h"

/**
 * Interface to Worker thread that dispatches commands to the OPAL subsystem
 **/
@interface XMOpalDispatcher : NSObject {

	NSPort *receivePort;
	
	unsigned callID;
	
	NSTimer *gatekeeperRegistrationCheckTimer;
	
	NSTimer *callStatisticsUpdateIntervalTimer;
	
	NSLock *registrarRegistrationWaitLock;
	
}

+ (void)_setPreferences:(XMPreferences *)preferences externalAddress:(NSString *)externalAddress;
+ (void)_retryEnableH323:(XMPreferences *)preferences;
+ (void)_retryGatekeeperRegistration:(XMPreferences *)preferences;
+ (void)_retryEnableSIP:(XMPreferences *)preferences;
+ (void)_retryRegistrarRegistrations:(XMPreferences *)preferences;

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

- (id)_init;
- (void)_close;

	// called every time the Framework registers at a gatekeeper
	// called on the OpalDispatcherThread, therefore safe
- (void)_handleGatekeeperRegistration:(NSString *)gatekeeperName;

	// Called every time the Framework unregisters from a gatekeeper
	// Called on the OpalDispatcherThread, therefore safe
- (void)_handleGatekeeperUnregistration;

	// called every time the Framework completes SIP Registration
    // may be called on any thread
- (void)_handleRegistrarSetupCompleted;

@end

#endif // _XM_OPAL_DISPATCHER_H__
