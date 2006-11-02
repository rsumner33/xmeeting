/*
 * $Id: XMDialPadModule.h,v 1.6 2006/11/02 22:30:00 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_DIAL_PAD_MODULE_H__
#define __XM_DIAL_PAD_MODULE_H__

#import <Cocoa/Cocoa.h>
#import "XMInspectorModule.h"

@class XMInstantActionButton;

@interface XMDialPadModule : XMInspectorModule {

	IBOutlet NSView *contentView;
	NSSize contentViewSize;
	
	IBOutlet NSButton *button0;
	IBOutlet NSButton *button1;
	IBOutlet NSButton *button2;
	IBOutlet NSButton *button3;
	IBOutlet NSButton *button4;
	IBOutlet NSButton *button5;
	IBOutlet NSButton *button6;
	IBOutlet NSButton *button7;
	IBOutlet NSButton *button8;
	IBOutlet NSButton *button9;
	IBOutlet NSButton *button10;
	IBOutlet NSButton *button11;
	
	IBOutlet XMInstantActionButton *upButton;
	IBOutlet XMInstantActionButton *leftButton;
	IBOutlet XMInstantActionButton *rightButton;
	IBOutlet XMInstantActionButton *downButton;
	IBOutlet XMInstantActionButton *zoomInButton;
	IBOutlet XMInstantActionButton *zoomOutButton;
	
	IBOutlet NSPopUpButton *userInputModePopUp;
}

- (IBAction)userInputToneButtonPressed:(id)sender;
- (IBAction)userInputModeChanged:(id)sender;

@end

#endif // __XM_DIAL_PAD_MODULE_H__
