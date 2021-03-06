/*
 * $Id: XMVideoModule.h,v 1.3 2006/02/09 01:43:11 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_MODULE_H__
#define __XM_VIDEO_MODULE_H__

#import <Cocoa/Cocoa.h>

@protocol XMVideoModule <NSObject>

/**
 * Identifier for the module. Unique and non-localizable
 **/
- (NSString *)identifier;

/**
 * Name of the module. Localized.
 **/
- (NSString *)name;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)isEnabled;

/**
 * Returns whether this module has any settings or not
 **/
- (BOOL)hasSettings;

- (NSDictionary *)permamentSettings;
- (BOOL)setPermamentSettings:(NSDictionary *)settings;

- (NSView *)settingsView;

- (void)setDefaultSettings;

@end

#endif // __XM_VIDEO_MODULE_H__

