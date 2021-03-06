/*
 * $Id: XMSequenceGrabberVideoInputModule.h,v 1.10 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__
#define __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "XMVideoInputModule.h"


@interface XMSequenceGrabberVideoInputModule : NSObject <XMVideoInputModule> {
	
@private
  id<XMVideoInputManager> inputManager;
  
  SGDeviceList deviceList;
  NSArray *deviceNames;
  NSArray *deviceNameIndexes;
  NSString *selectedDevice;
  
  SeqGrabComponent sequenceGrabber;
  SGChannel videoChannel;
  SGDataUPP dataGrabUPP;
  ICMDecompressionSessionRef grabDecompressionSession;
  TimeValue lastTime;
  TimeValue timeScale;
  TimeValue desiredFrameDuration;
  
  NSSize frameSize;
  unsigned framesPerSecond;
  
  BOOL isGrabbing;
  unsigned callbackMissCounter;
  unsigned callbackStatus;
  
  unsigned short brightness;
  unsigned short hue;
  unsigned short saturation;
  unsigned short contrast;
  unsigned short sharpness;
  
  IBOutlet NSView *settingsView;
  
  IBOutlet NSSlider *brightnessSlider;
  IBOutlet NSTextField *brightnessField;
  IBOutlet NSSlider *hueSlider;
  IBOutlet NSTextField *hueField;
  IBOutlet NSSlider *saturationSlider;
  IBOutlet NSTextField *saturationField;
  IBOutlet NSSlider *contrastSlider;
  IBOutlet NSTextField *contrastField;
  IBOutlet NSSlider *sharpnessSlider;
  IBOutlet NSTextField *sharpnessField;
  
  OSErr openAndConfigureChannelErr;
}

- (id)_init;

- (void)_setVideoValues:(NSArray *)values;

- (IBAction)_sliderValueChanged:(id)sender;

@end

#endif // __XM_SEQUENCE_GRABBER_VIDEO_INPUT_MODULE_H__