/*
 * $Id: XMStatisticsModule.h,v 1.6 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_STATISTICS_MODULE_H__
#define __XM_STATISTICS_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorModule.h"

@class XMCallInfo;

@interface XMStatisticsModule : XMInspectorModule {
	
	IBOutlet NSView *contentView;
	NSSize collapsedContentViewSize;
	NSSize expandedContentViewSize;
	
	IBOutlet NSTableView *codecTableView;
	IBOutlet NSButton *extraInformationDisclosure;
	
	IBOutlet NSTextField *roundTripDelayField;
	IBOutlet NSTextField *packetsLostField;
	IBOutlet NSTextField *packetsLateField;
	IBOutlet NSTextField *packetsOutOfOrderField;
	IBOutlet NSTextField *packetSendTimeField;
	IBOutlet NSTextField *packetReceiveTimeField;
	
	IBOutlet NSBox *callInformationBox;
	IBOutlet NSTextField *remotePartyNameField;
	IBOutlet NSTextField *callDurationField;
	
	NSNib *nibLoader;
	
	XMCallInfo *activeCall;
	
	BOOL isExpanded;
	
	NSDate *oldDate;
	float oldAudioBytesSent;
	float oldAudioBytesReceived;
	float oldVideoBytesSent;
	float oldVideoBytesReceived;
	
	float audioSendBitrate;
	float audioReceiveBitrate;
	float videoSendBitrate;
	float videoReceiveBitrate;
	
	float avgAudioSendBitrate;
	float avgAudioReceiveBitrate;
	float avgVideoSendBitrate;
	float avgVideoReceiveBitrate;
}

- (IBAction)toggleShowExtraInformation:(id)sender;

@end

#endif // __XM_STATISTICS_MODULE_H__
