/*
 * $Id: XMSIPAccount.m,v 1.1 2006/03/13 23:46:21 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#import "XMSIPAccount.h"

#import "XMPreferencesManager.h"

NSString *XMKey_SIPAccountName = @"XMeeting_SIPAccountName";
NSString *XMKey_SIPAccountRegistrar = @"XMeeting_SIPAccountRegistrar";
NSString *XMKey_SIPAccountUsername = @"XMeeting_SIPAccountUsername";

@interface XMSIPAccount (PrivateMethods)

- (id)_initWithTag:(unsigned)tag;

@end

@implementation XMSIPAccount

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
	return [self _initWithTag:0];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	self = [self _initWithTag:0];
	
	NSObject *obj;
	Class stringClass = [NSString class];
	
	obj = [dictionary objectForKey:XMKey_SIPAccountName];
	if(obj != nil && [obj isKindOfClass:stringClass])
	{
		[self setName:(NSString *)obj];
	}
	obj = [dictionary objectForKey:XMKey_SIPAccountRegistrar];
	if(obj != nil && [obj isKindOfClass:stringClass])
	{
		[self setRegistrar:(NSString *)obj];
	}
	obj = [dictionary objectForKey:XMKey_SIPAccountUsername];
	if(obj != nil && [obj isKindOfClass:stringClass])
	{
		[self setUsername:(NSString *)obj];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMSIPAccount *sipAccount = [[[self class] allocWithZone:zone] _initWithTag:[self tag]];
	
	[sipAccount setName:[self name]];
	[sipAccount setRegistrar:[self registrar]];
	[sipAccount setUsername:[self username]];
	[sipAccount setPassword:[self password]];
	
	return sipAccount;
}

- (id)_initWithTag:(unsigned)theTag
{
	self = [super init];
	
	static unsigned nextTag = 0;
	
	if(theTag == 0)
	{
		theTag = ++nextTag;
	}
	
	tag = theTag;
	name = nil;
	registrar = nil;
	username = nil;
	didLoadPassword = NO;
	password = nil;
	
	return self;
}

- (void)dealloc
{
	[name release];
	[registrar release];
	[username release];
	[password release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Getting Different Representations

- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if(name != nil)
	{
		[dictionary setObject:name forKey:XMKey_SIPAccountName];
	}
	if(registrar != nil)
	{
		[dictionary setObject:registrar forKey:XMKey_SIPAccountRegistrar];
	}
	if(username != nil)
	{
		[dictionary setObject:username forKey:XMKey_SIPAccountUsername];
	}
	
	return dictionary;
}

#pragma mark -
#pragma mark Accessor Methods

- (unsigned)tag
{
	return tag;
}

- (NSString *)name
{
	return name;
}

- (void)setName:(NSString *)theName
{
	if(name != theName)
	{
		NSString *old = name;
		name = [theName copy];
		[old release];
	}
}

- (NSString *)registrar
{
	return registrar;
}

- (void)setRegistrar:(NSString *)theRegistrar
{
	if(registrar != theRegistrar)
	{
		NSString *old = registrar;
		registrar = [theRegistrar copy];
		[old release];
	}
}

- (NSString *)username
{
	return username;
}

- (void)setUsername:(NSString *)theUsername
{
	if(username != theUsername)
	{
		NSString *old = username;
		username = [theUsername copy];
		[old release];
	}
}

- (NSString *)password
{
	if(password == nil && didLoadPassword == NO)
	{
		[self setPassword:[[XMPreferencesManager sharedInstance] passwordForServiceName:registrar accountName:username]];
		didLoadPassword = YES;
	}
	return password;
}

- (void)setPassword:(NSString *)thePassword
{
	if(password != thePassword)
	{
		NSString *old = password;
		password = [thePassword copy];
		[old release];
	}
}

- (void)clearPassword
{
	[self setPassword:nil];
	didLoadPassword = NO;
}

- (void)savePassword
{
	[[XMPreferencesManager sharedInstance] setPassword:password forServiceName:registrar accountName:username];
}

@end