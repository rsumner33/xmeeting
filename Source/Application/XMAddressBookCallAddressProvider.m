/*
 * $Id: XMAddressBookCallAddressProvider.m,v 1.14 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookCallAddressProvider.h"

#import "XMeeting.h"
#import "XMAddressBookManager.h"
#import "XMAddressBookRecord.h"
#import "XMSimpleAddressResource.h"
#import "XMPreferencesManager.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"

@interface XMAddressBookCallAddressProvider (PrivateMethods)

- (id)_init;

@end

@implementation XMAddressBookCallAddressProvider

#pragma mark Class Methods

+ (XMAddressBookCallAddressProvider *)sharedInstance
{
  static XMAddressBookCallAddressProvider *sharedInstance = nil;
  
  if (sharedInstance == nil) {
    sharedInstance = [[XMAddressBookCallAddressProvider alloc] _init];
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
  isActiveCallAddressProvider = NO;
  return self;
}

- (void)dealloc
{	
  if (isActiveCallAddressProvider) {
    [[XMCallAddressManager sharedInstance] removeCallAddressProvider:self];
  }
  
  [super dealloc];
}

#pragma mark Activating / Deactivating this provider

- (BOOL)isActiveCallAddressProvider
{
  return isActiveCallAddressProvider;
}

- (void)setActiveCallAddressProvider:(BOOL)flag
{
  if (flag == isActiveCallAddressProvider) {
    return;
  }
  
  if (flag == YES) {
    [[XMCallAddressManager sharedInstance] addCallAddressProvider:self];
    isActiveCallAddressProvider = YES;
  } else {
    [[XMCallAddressManager sharedInstance] removeCallAddressProvider:self];
    isActiveCallAddressProvider = NO;
  }
}

#pragma mark XMCallAddressProvider Methods

- (NSArray *)addressesMatchingString:(NSString *)searchString
{
  XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
  NSArray *matchedRecords = [addressBookManager recordsMatchingString:searchString];
  return matchedRecords;
}

- (NSString *)completionStringForAddress:(id<XMCallAddress>)address uncompletedString:(NSString *)uncompletedString
{
  XMAddressBookRecord *record = (XMAddressBookRecord *)address;
  XMAddressBookRecordPropertyMatch propertyMatch = [record propertyMatch];
  NSRange searchRange = NSMakeRange(0, [uncompletedString length]);
  
  if (propertyMatch == XMAddressBookRecordPropertyMatch_CallAddressMatch) {
    // we have a match for the Address. In this case, we allow only the call address
    // to be entered. (not e.g. "callAddress" (displayName)". This eases the check
    // since we only have to check wether uncompletedString is a Prefix to the
    // call address.
    NSString *callAddress = [record humanReadableCallAddress];
    if (searchRange.length > [callAddress length]) {
      return nil;
    }
    
    NSRange prefixRange = [callAddress rangeOfString:uncompletedString
                                             options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSAnchoredSearch)
                                               range:searchRange];
    if (prefixRange.location == NSNotFound) {
      // since uncompletedString is not a prefix to the callAddress, this record is
      // not a valid record for completion
      return nil;
    }
    NSString *displayName = [record displayName];
    
    // producing the display string
    return [NSString stringWithFormat:@"%@ (%@)", callAddress, displayName];
	} else if (propertyMatch == XMAddressBookRecordPropertyMatch_CompanyMatch) {
    // a company match has a similar behavior as a call address match.
    // only if uncompletedString is a prefix to company name, we have a match.
    NSString *companyName = [record companyName];
    if (searchRange.length > [companyName length]) {
      return nil;
    }
    
    NSRange prefixRange = [companyName rangeOfString:uncompletedString
                                             options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
                                               range:searchRange];
    if (prefixRange.location == NSNotFound) {
      return nil;
    }
	
    NSString *callAddress = [record humanReadableCallAddress];
    return [NSString stringWithFormat:@"%@ <%@>", companyName, callAddress];
  } else if (propertyMatch == XMAddressBookRecordPropertyMatch_PhoneNumberMatch) {
    NSString *callAddress = [record humanReadableCallAddress];
    if (searchRange.length > [callAddress length]) {
      return nil;
    }
    
    NSRange prefixRange = [callAddress rangeOfString:uncompletedString
                                             options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
                                               range:searchRange];
    if (prefixRange.location == NSNotFound) {
      return nil;
    }
    
    NSString *displayName = [record displayName];
    return [NSString stringWithFormat:@"%@ (%@)", callAddress, displayName];
  } else {
    // this is the most complicated case. the record matched either a first name or a last name,
    // which determines the order in which to display the two values. In addition, the user may
    // enter e.g. ("firstName" "lastName"), which has to be detected correctly.
    NSString *firstName = [record firstName];
    NSString *lastName = [record lastName];
    
    if (firstName == nil) {
      // only the last name can be shown, if the last name has not the uncompletedString as its prefix
      // this record is discarded as well.
      if (searchRange.length > [lastName length]) {
        return nil;
      }
      
      NSRange prefixRange = [lastName rangeOfString:uncompletedString
                                            options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
                                              range:searchRange];
      if (prefixRange.location == NSNotFound) {
        return nil;
      }
      
      return lastName;
    } else if (lastName == nil) {
      // the same as in the case of !firstName
      if (searchRange.length > [firstName length]) {
        return nil;
      }
      
      NSRange prefixRange = [firstName rangeOfString:uncompletedString
                                             options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
                                               range:searchRange];
      if (prefixRange.location == NSNotFound) {
        return nil;
      }
      return firstName;
    } else {
      // Now, it's getting funny. The uncompletedString may be more than just the property matched,
      // but still the match may be correct
      NSString *firstPart;
      NSString *lastPart;
      
      if (propertyMatch == XMAddressBookRecordPropertyMatch_FirstNameMatch) {
        firstPart = firstName;
        lastPart = lastName;
      } else {
        firstPart = lastName;
        lastPart = firstName;
      }
      
      NSString *displayName = [NSString stringWithFormat:@"%@ %@", firstPart, lastPart];
      
      // a match for "firstPart lastPart <Address>" isn't searched. If the text entered is too long,
      // simply abort
      if (searchRange.length > [displayName length]) {
        return nil;
      }
      
      NSRange prefixRange = [displayName rangeOfString:uncompletedString
                                               options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
                                                 range:searchRange];
      if (prefixRange.location == NSNotFound) {
        // it might now be that the combination "lastPart firstPart" matches
        // if so, check this
        displayName = [NSString stringWithFormat:@"%@ %@", lastPart, firstPart];
        
        prefixRange = [displayName rangeOfString:uncompletedString
                                         options:(NSCaseInsensitiveSearch | NSAnchoredSearch)
                                           range:searchRange];
        if (prefixRange.location == NSNotFound) {
          return nil;
        }
      }
      
      NSString *callAddress = [record humanReadableCallAddress];
      return [NSString stringWithFormat:@"%@ <%@>", displayName, callAddress];
    }
  }
}

- (id<XMCallAddress>)addressMatchingResource:(XMAddressResource *)addressResource
{
  XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
  XMAddressBookRecord *record = [addressBookManager recordWithCallAddress:[addressResource address]];
  
  if (record != nil) {
    return record;
  }
  
  // If the address itself doesn't match, no address book instance should be returned,
  // as the provided address resource may have extra parameters set, etc.
  // So, search for matches, but return a SimpleAddressResource instance instead.
  
  NSString *username = [addressResource username];
  NSString *host = [addressResource host];
  NSString * addr = nil;
  
  if (username != nil && host != nil) {
    addr = [NSString stringWithFormat:@"%@@%@", username, host];
  } else if (username != nil) {
    addr = username;
  } else if (host != nil) {
    addr = host;
  } else {
    return nil;
  }

  record = [addressBookManager recordWithCallAddress:addr];
  if (record == nil) {
    // No matches based on the address
    if (username != nil && host != nil && [addressResource callProtocol] == XMCallProtocol_SIP) {
      // If the 'username' part is a phone number found in the address book,
      // and the host part equals the current default account, treat this as a match as well.
      XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
      XMLocation *location = [prefManager activeLocation];
      unsigned tag = [location defaultSIPAccountTag];
      if ([prefManager addressBookPhoneNumberProtocol] == XMCallProtocol_SIP && [location enableSIP] && tag != 0) {
        NSString *domain = [[prefManager sipAccountWithTag:tag] domain];
        if ([host isEqualToString:domain]) {
          // search for the 'username' part only
          record = [addressBookManager recordWithCallAddress:username];
        }
      }
    }
  }
  
  if (record != nil) {
    XMSimpleAddressResource *simpleResource = [[XMSimpleAddressResource alloc] initWithAddress:[addressResource address] 
                                                                                   callProtocol:[addressResource callProtocol]];
    // Add display string / image from address book
    [simpleResource setDisplayString:[record displayString]];
    [simpleResource setDisplayImage:[record displayImage]];
    return [simpleResource autorelease];
  }
  
  return nil;
}

- (id<XMCallAddress>)addressMatchingResource:(XMAddressResource *)addressResource
{
    XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
    return [addressBookManager recordWithCallAddress:[addressResource address]];
}

- (NSArray *)alternativesForAddress:(id<XMCallAddress>)address selectedIndex:(unsigned *)selectedIndex
{
  XMAddressBookRecord *record = (XMAddressBookRecord *)address;
  
  NSArray *records = [[XMAddressBookManager sharedInstance] recordsForPersonWithRecord:record indexOfRecord:selectedIndex];
  
  unsigned count = [records count];
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
  for (unsigned i = 0; i < count; i++)
  {
    XMAddressBookRecord *theRecord = (XMAddressBookRecord *)[records objectAtIndex:i];
    NSString *callAddress = [theRecord humanReadableCallAddress];
    [array addObject:callAddress];
  }
  
  return array;
}

- (id<XMCallAddress>)alternativeForAddress:(id<XMCallAddress>)address atIndex:(unsigned)index
{
  XMAddressBookRecord *record = (XMAddressBookRecord *)address;
  
  unsigned indexOfRecord;
  NSArray *records = [[XMAddressBookManager sharedInstance] recordsForPersonWithRecord:record indexOfRecord:&indexOfRecord];
  
  return (id<XMCallAddress>)[records objectAtIndex:index];
}

- (NSArray *)allAddresses
{
  XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
  return [addressBookManager records];
}

- (XMProviderPriority)priorityForAllAddresses
{
  return XMProviderPriority_Low;
}

@end
