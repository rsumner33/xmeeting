/*
 * $Id: XMLocalVideoView.h,v 1.1 2006/03/22 08:54:51 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich, Ivan Guajana. All rights reserved.
 */

#ifndef __XM_LOCAL_VIDEO_VIEW_H__
#define __XM_LOCAL_VIDEO_VIEW_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

/**
 * A simple view that draws the local video
 * This view is used for preview of the local video
 * when not in a call. The code is kept as simple as
 * possible, just drawing the video frames.
 **/
@interface XMLocalVideoView : NSView <XMVideoView> {

	unsigned displayStatus;
	
	NSOpenGLContext *openGLContext;
	NSSize displaySize;
	
	// used in case we can't directly use OpenGL
	// (miniaturized window)
	NSCIImageRep *videoImageRep;
	BOOL isMiniaturized;
	
	// indicates that something video-related is in progress
	NSWindow *busyWindow;
	NSProgressIndicator *busyIndicator;
	
	// displayed when -startDisplayingNoVideo is called
	NSImage *noVideoImage;
}

/**
 * Displaying local or no video are mutually exclusive.
 * If neither is chosen, the window background is drawn
 **/
- (void)startDisplayingLocalVideo;
- (void)stopDisplayingLocalVideo;
- (BOOL)doesDisplayLocalVideo;

- (void)startDisplayingNoVideo;
- (void)stopDisplayingNoVideo;
- (BOOL)doesDisplayNoVideo;

- (NSImage *)noVideoImage;
- (void)setNoVideoImage:(NSImage *)image;

@end

#endif // __XM_LOCAL_VIDEO_VIEW_H__
