/*
 * $Id: XMH323URL.m,v 1.1 2007/05/08 15:17:46 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#import "XMH323URL.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"

@implementation XMH323URL

#pragma mark -
#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)url
{
	return [url hasPrefix:@"h323:"];
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dict
{
	return NO;
}

+ (XMH323URL *)addressResourceWithStringRepresentation:(NSString *)url
{
	XMH323URL *h323URL = [[XMH323URL alloc] initWithStringRepresentation:url];
    if (h323URL != nil)
    {
        return [h323URL autorelease];
    }
    return nil;
}

+ (XMH323URL *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dict
{
	return nil;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)initWithStringRepresentation:(NSString *)stringRepresentation
{
    BOOL valid = YES;
    url = [stringRepresentation copy];
    
    if (![stringRepresentation hasPrefix:@"h323:"]) {
        valid = NO;
        goto bail;
    }
    
    address = [stringRepresentation substringFromIndex:5];
    [address retain];
    
    // Do some more validicy checking here!

bail:
    if (valid == NO)
    {
        [self release];
        return nil;
    }

    return self;
}

- (void)dealloc
{
    [url release];
    [address release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Getting Different Representations

- (NSString *)stringRepresentation
{
    return url;
}

- (NSDictionary *)dictionaryRepresentation
{
    return nil;
}

#pragma mark -
#pragma mark XMAddressResource interface

- (XMCallProtocol)callProtocol
{
    return XMCallProtocol_H323;
}

- (NSString *)address
{
    return address;
}

- (NSString *)humanReadableAddress
{
    return [self address];
}

@end
