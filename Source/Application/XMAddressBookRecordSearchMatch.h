/*
 * $Id: XMAddressBookRecordSearchMatch.h,v 1.3 2006/03/27 15:31:21 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_RECORD_SEARCH_MATCH_H__
#define __XM_ADDRESS_BOOK_RECORD_SEARCH_MATCH_H__

#import <Foundation/Foundation.h>

#import "XMCallAddressManager.h"



/**
 * Instances of this object encapsulate information about a
 * record matching some searchString. Besides the actual record,
 * also the information which part of the record matched the searchString
 * is stored in this instance and can be queried
 **/
@interface XMAddressBookRecordSearchMatch : NSObject <XMCallAddress> {
	
	id record;
//	XMAddressBookRecordPropertyMatch propertyMatch;
	
}

/**
 * Returns the address book record
 **/
- (id)record;

/**
 * Returns which part of the record matched the search string
 **/
//- (XMAddressBookRecordPropertyMatch)propertyMatch;

@end

#endif // __XM_ADDRESS_BOOK_RECORD_SEARCH_MATCH_H__
