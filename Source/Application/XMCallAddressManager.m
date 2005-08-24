/*
 * $Id: XMCallAddressManager.m,v 1.5 2005/06/30 09:33:09 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallAddressManager.h"

@interface XMCallAddressManager (PrivateMethods)

- (id)_init;

- (void)_callCleared:(NSNotification *)notif;

@end

@implementation XMCallAddressManager

#pragma mark Class Methods

+ (XMCallAddressManager *)sharedInstance
{
	static XMCallAddressManager *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMCallAddressManager alloc] _init];
	}
	return sharedInstance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	callAddressProviders = [[NSMutableArray alloc] initWithCapacity:3];
	activeCallAddress = nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_callCleared:)
												 name:XMNotification_CallManagerCallCleared object:nil];
	
	return self;
}

- (void)dealloc
{
	[callAddressProviders release];
	
	[super dealloc];
}

#pragma mark handling CallAddressProviders

- (void)addCallAddressProvider:(id<XMCallAddressProvider>)provider
{
	[callAddressProviders addObject:provider];
}

- (void)removeCallAddressProvider:(id<XMCallAddressProvider>)provider
{
	[callAddressProviders removeObject:provider];
}

#pragma mark handling call addresses

- (NSArray *)addressesMatchingString:(NSString *)searchString
{
	unsigned i;
	unsigned count = [callAddressProviders count];
	
	NSMutableArray *matches = [NSMutableArray arrayWithCapacity:10];
	
	for(i = 0; i < count; i++)
	{
		id<XMCallAddressProvider> provider = (id<XMCallAddressProvider>)[callAddressProviders objectAtIndex:i];
		NSArray *providerMatches = [provider addressesMatchingString:searchString];
		
		[matches addObjectsFromArray:providerMatches];
	}
	
	return matches;
}

- (NSString *)completionStringForAddress:(id<XMCallAddress>)address uncompletedString:(NSString *)uncompletedString
{
	id<XMCallAddressProvider> provider = [address provider];
	
	if(provider == nil)
	{
		return nil;
	}
	return [provider completionStringForAddress:address uncompletedString:uncompletedString];
}

- (id<XMCallAddress>)activeCallAddress
{
	return activeCallAddress;
}

- (BOOL)makeCallToAddress:(id<XMCallAddress>)callAddress
{
	if(activeCallAddress != nil)
	{
		return NO;
	}

	BOOL result = [[XMCallManager sharedInstance] callURL:[callAddress url]];
	
	if(result == YES)
	{
		activeCallAddress = [callAddress retain];
		return YES;
	}
	
	activeCallAddress = nil;
	return NO;
}

#pragma mark Private Methods

- (void)_callCleared:(NSNotification *)notif
{
	[activeCallAddress release];
	activeCallAddress = nil;
}

@end