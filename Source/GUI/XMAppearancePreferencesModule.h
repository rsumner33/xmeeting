/*
 * $Id: XMAppearancePreferencesModule.h,v 1.1 2006/06/13 20:27:18 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_APPEARANCE_PREFERENCES_MODULE_H__
#define __XM_APPEARANCE_PREFERENCES_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMPreferencesModule.h"

@interface XMAppearancePreferencesModule : NSObject <XMPreferencesModule> {

	XMPreferencesWindowController *prefWindowController;
	
	IBOutlet NSView *contentView;
	float contentViewHeight;
	
	IBOutlet NSButton *automaticallyEnterFullScreenSwitch;
	IBOutlet NSButton *showSelfViewMirroredSwitch;
	IBOutlet NSButton *automaticallyHideInCallControlsSwitch;
	IBOutlet NSPopUpButton *inCallControlsHideAndShowEffectPopUp;
	
	IBOutlet NSButton *playSoundOnIncomingCallSwitch;
	IBOutlet NSPopUpButton *soundTypePopUp;
	
}

- (IBAction)defaultAction:(id)sender;
- (IBAction)toggleAutomaticallyHideInCallControls:(id)sender;
- (IBAction)togglePlaySoundOnIncomingCall:(id)sender;

@end

#endif // __XM_APPEARANCE_PREFERENCES_MODULE_H__