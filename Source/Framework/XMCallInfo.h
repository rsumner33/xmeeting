/*
 * $Id: XMCallInfo.h,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

/**
 * This class encapsulates all information about a specific call,
 * whether this is a call to or from an remote endpoint.
 * Instances of this class can be queried about the remote name,
 * the protocol used (H.323 or SIP) and additional informations
 * to customise the call which can be defined in a callto: / h323:
 * or sip: url.
 **/

#import <Cocoa/Cocoa.h>

#import "XMTypes.h"


@interface XMCallInfo : NSObject {
	
@private
	unsigned callID;	//identifier for the call token in OPAL
	
	XMCallProtocol protocol;
	NSString *remoteName;
	NSString *remoteNumber;
	NSString *remoteAddress;
	NSString *remoteApplication;
	
	XMCallStatus callStatus;
	XMCallEndReason callEndReason;
	
	NSTimeInterval startTime;
	
	NSString *incomingAudioCodec;
	NSString *outgoingAudioCodec;
}

/**
* Obtain the call protocol in use
 **/
- (XMCallProtocol)protocol;

/**
 * Obtain the remote party's name.
 * Returns nil if there is no remote name
 * (remote party not found)
 **/
- (NSString *)remoteName;

/**
 * Obtain the remote party's e164 number.
 * Returns nil if the remote party has no number
 **/
- (NSString *)remoteNumber;

/**
 * Obtain the remote party's address.
 * Returns nil if the remoty party has no
 * address (remote party not found)
 **/
- (NSString *)remoteAddress;

/**
 * Obtain the remote party's application.
 * Returns nil if the remote party's application
 * cannot be determined (remote party not found)
 **/
- (NSString *)remoteApplication;

/**
 * Returns the current state of the call
 **/
- (XMCallStatus)currentStatus;

/**
 * Returns the reason why the call was ended.
 * Note that the return value is only meaningful
 * if the call is ended. Otherwise, NumCallEndReasons
 * will be returned
 **/
- (XMCallEndReason)callEndReason;

/**
 * Obtain the duration of the call. If the call is not active, the duration will be 0.
 * Else the current duration or the total time the call was active is returned
 **/
- (NSTimeInterval)callDuration;

/**
 * Returns the audio codec used for the incoming audio stream
 **/
- (NSString *)incomingAudioCodec;

/**
 * Returns the audio codec used for the outgoing audio stream
 **/
- (NSString *)outgoingAudioCodec;

@end
