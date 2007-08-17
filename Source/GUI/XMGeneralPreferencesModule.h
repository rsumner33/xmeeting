/*
 * $Id: XMGeneralPreferencesModule.h,v 1.7 2007/08/17 11:36:43 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_GENERAL_PREFERENCES_MODULE_H__
#define __XM_GENERAL_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

extern NSString *XMKey_GeneralPreferencesModuleIdentifier;

@class XMPreferencesWindowController;

@interface XMGeneralPreferencesModule : NSObject <XMPreferencesModule> {
  
@private
  XMPreferencesWindowController *prefWindowController;
  float contentViewHeight;
  IBOutlet NSView *contentView;
  
  IBOutlet NSTextField *userNameField;
  IBOutlet NSButton *automaticallyAcceptIncomingCallsSwitch;
  IBOutlet NSButton *generateDebugLogSwitch;
  IBOutlet NSTextField *debugLogFilePathField;
  IBOutlet NSButton *chooseDebugLogFilePathButton;
}

- (IBAction)defaultAction:(id)sender;

- (IBAction)toggleGenerateDebugLogFile:(id)sender;
- (IBAction)chooseDebugFilePath:(id)sender;

@end

#endif // __XM_GENERAL_PREFERENCES_MODULE_H__
