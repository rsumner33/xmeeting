/*
 * $Id: XMPreferencesRegistrationRecord.h,v 1.2 2007/08/17 11:36:42 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_REGISTRATION_RECORD_H__
#define __XM_PREFERENCES_REGISTRATION_RECORD_H__

#import <Cocoa/Cocoa.h>

@interface XMPreferencesRegistrationRecord : NSObject <NSCopying, NSCoding> {

@private
  NSString *domain;
  NSString *username;
  NSString *authorizationUsername;
  NSString *password;

}

- (NSMutableDictionary *)dictionaryRepresentation;

- (NSString *)domain;
- (void)setDomain:(NSString *)domain;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (NSString *)authorizationUsername;
- (void)setAuthorizationUsername:(NSString *)authorizationUsername;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

- (NSString *)registration;

@end

#endif // __XM_PREFERENCES_REGISTRATION_RECORD_H__
