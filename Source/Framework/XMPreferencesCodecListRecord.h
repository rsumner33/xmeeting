/*
 * $Id: XMPreferencesCodecListRecord.h,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_CODEC_LIST_RECORD_H__
#define __XM_PREFERENCES_CODEC_LIST_RECORD_H__

#import <Foundation/Foundation.h>
#import "XMTypes.h"
	
/**
 * An instance of XMPreferencesCodecListRecord encapsulates all relevant
 * information for a codec (its key and its status (enabled / disabled))
 * This class is used within XMPreferences instances to maintain the
 * codec preference order list for the audio and video codecs.
 * The available codecs and additional information about the codecs can
 * be found using the XMCodecManager API.
 **/
@interface XMPreferencesCodecListRecord : NSObject <NSCopying, NSCoding>
{
@private
  XMCodecIdentifier identifier;
  BOOL isEnabled;
}

/**
 * Creates a dictionary representation of this object
 **/
- (NSMutableDictionary *)dictionaryRepresentation;

/**
 * Obtain the values using keys
 **/
- (id)propertyForKey:(NSString *)key;
- (void)setProperty:(id)property forKey:(NSString *)key;

/**
 * Returns the codec identifier associated with this instance.
 **/
- (XMCodecIdentifier)identifier;

/**
 * Dealing with the enabled/disabled status
 **/
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

@end

#endif // __XM_PREFERENCES_CODEC_LIST_RECORD_H__
