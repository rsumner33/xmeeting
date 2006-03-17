/*
 * $Id: XMNoCallModule.h,v 1.12 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_NO_CALL_MODULE_H__
#define __XM_NO_CALL_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMMainWindowModule.h"
#import "XMDatabaseField.h"

@class XMLocalVideoView;

/**
 * XMNoCallModule is the main window module displayed when the
 * application is not in a call.
 **/
@interface XMNoCallModule : NSObject <XMMainWindowModule, XMDatabaseFieldDataSource> {
	
	// XMMainWindowModule Outlets and variables
	IBOutlet NSView *contentView;
	
	NSSize contentViewSizeWithSelfViewHidden;
	NSSize contentViewSizeWithSelfViewShown;
	NSSize currentContentViewSizeWithSelfViewShown;
	
	// GUI Outlets
	IBOutlet XMLocalVideoView *selfView;
	IBOutlet NSImageView *semaphoreView;
	IBOutlet NSProgressIndicator *busyIndicator;
	IBOutlet NSTextField *statusField;
	IBOutlet NSPopUpButton *locationsPopUpButton;
	IBOutlet XMDatabaseField *callAddressField;
	IBOutlet NSButton *callButton;
	
	// Optimizations for XMDatabaseField completions
	unsigned uncompletedStringLength;
	NSMutableArray *matchedAddresses;
	NSMutableArray *completions;
	
	NSNib *nibLoader;
	
	BOOL doesShowSelfView;
	BOOL isCalling;
}

- (IBAction)call:(id)sender;
- (IBAction)changeActiveLocation:(id)sender;
- (IBAction)showInspector:(id)sender;
- (IBAction)showTools:(id)sender;
- (IBAction)showContacts:(id)sender;
- (IBAction)toggleShowSelfView:(id)sender;


@end

#endif // __XM_NO_CALL_MODULE_H__