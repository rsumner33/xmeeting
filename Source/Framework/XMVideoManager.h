/*
 * $Id: XMVideoManager.h,v 1.21 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_MANAGER_H__
#define __XM_VIDEO_MANAGER_H__

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "XMTypes.h"
#import "XMVideoView.h"
#import "XMVideoModule.h"

/**
 * The XMeeting framework uses a highly optimized, extensible
 * and flexible engine using QuickTime, CoreVideo and OpenGL
 * to
 * - grab video from a local video source (e.g. webcam),
 * - compress/decompress video data and
 * - display the video data on screen
 *
 * XMVideoManager is the interface to this engine, with the help
 * of the XMVideoView protocol. This manager provides methods to
 * select input devices, register interested video draw views and
 * get additional information.
 * The XMeeting framework does not provide actual code to draw the
 * video data on screen but faciliates this task through the
 * XMVideoView protocol. To draw on screen, OpenGL has to be used.
 * This way, the application can add their own rendering code used
 * to display the frames on screen.
 **/
@interface XMVideoManager : NSObject {
	
@private
  NSMutableArray *videoViews;
  
  NSArray *inputDevices;
  NSString *selectedInputDevice;
  id<XMVideoModule> selectedVideoModule;
  
  BOOL isDoingVideoDisplay;
  XMVideoSize localVideoSize;
  XMVideoSize remoteVideoSize;
  NSSize remoteVideoDimensions;
  
  NSLock *videoLock;
  NSOpenGLPixelFormat *openGLPixelFormat;
  NSOpenGLContext *openGLContext;
  CVOpenGLTextureCacheRef textureCache;
  CVOpenGLTextureRef localVideoTexture;
  BOOL localVideoTextureDidChange;
  CVOpenGLTextureRef remoteVideoTexture;
  BOOL remoteVideoTextureDidChange;
  CVDisplayLinkRef displayLink;
  
  NSString *errorDescription;
}

/**
 * Returns the shared singleton instance of this class
 **/
+ (XMVideoManager *)sharedInstance;

/**
 * Returns an array of strings containing the input devices.
 * Note that this method does not return valid devices before
 * the appropriate Notification.
 **/
- (NSArray *)inputDevices;

/**
 * Discards the current device list and refreshes the list
 * Note that the new device list isn't available until the
 * appropriate notification is posted. Sometimes, creating
 * a new device list might take some time (1s or even more)
 **/
- (void)updateInputDeviceList;

/**
 * Returns the currently selected device
 **/
- (NSString *)selectedInputDevice;

/**
 * Sets the device to use. Does nothing if inputDevice isn't a valid
 * device.
 **/
- (void)setSelectedInputDevice:(NSString *)inputDevice;

/**
 * Returns the video module providing the currently selected
 * input device
 **/
- (id<XMVideoModule>)videoModuleProvidingSelectedInputDevice;

/**
 * Returns whether the device specified has any settings or not
 **/
- (BOOL)deviceHasSettings:(NSString *)device;

/**
 * Returns whether this input device requires a settings dialog to be shown
 * when the input device gets selected.
 **/
- (BOOL)requiresSettingsDialogWhenDeviceIsSelected:(NSString *)inputDevice;

/**
 * Returns a view handling the settings for the device specified
 **/
- (NSView *)settingsViewForDevice:(NSString *)device;

/**
 * Resets the settings for the device specified to default values
 **/
- (void)setDefaultSettingsForDevice:(NSString *)device;

/**
 * Returns the number of video modules available
 **/
- (unsigned)videoModuleCount;

/**
 * Returns the video module at the index specified
 **/
- (id<XMVideoModule>)videoModuleAtIndex:(unsigned)index;

/**
 * Returns whether the video display process is running or not. The display
 * process does only run when there is at least one video view attached
 **/
- (BOOL)isDoingVideoDisplay;

/**
 * Returns whether the manager is sending video or not
 **/
- (BOOL)isSendingVideo;

/**
 * Returns whether the manager is receiving video or not
 **/
- (BOOL)isReceivingVideo;

/**
 * Returns the size of the video currently transmitted.
 * If no video is transmitted, this method returns
 * XMVideoSize_NoVideo
 **/
- (XMVideoSize)localVideoSize;

/**
 * Returns the size of the remote video currently received.
 * If no video is received, returns XMVideoSize_NoVideo.
 **/
- (XMVideoSize)remoteVideoSize;

/**
 * Returns the dimensions of the remote video frame
 * If -remoteVideoSize is XMVideoSize_Custom,
 * this method returns the actual dimensions of the video
 * frame
 **/
- (NSSize)remoteVideoDimensions;

/**
 * Adds videoView to the list of views interested in rendering
 * local and/or remote video on the screen.
 * This method contains an implicit call to -forceRenderingForView,
 * thus when this method returns, -renderLocalVideo:remoteVideo:
 * has been called at least once.
 **/
- (void)addVideoView:(id<XMVideoView>)videoView;

/**
 * Removes videoView from the list of views interested in
 * rendering video
 **/
- (void)removeVideoView:(id<XMVideoView>)videoView;

/**
 * Returns the OpenGL pixel format to be used when creating
 * OpenGL contexts used to render video
 **/
- (NSOpenGLPixelFormat *)openGLPixelFormat;

/**
 * Returns the OpenGL context with which the OpenGL textures
 * are created. The contexts used by the application to draw
 * video on screen must share this context
 **/
- (NSOpenGLContext *)openGLContext;

/**
 * Causes the manager call -renderLocalVideo:remoteVideo:
 * on videoView after the system has been locked properly.
 * This method works also for views which arent't registered
 * using -addVideoView.
 * This method is useful if a view needs to draw on the
 * main thread.
 **/
- (void)forceRenderingForView:(id<XMVideoView>)videoView;

/**
 * Causes the video manager to lock all video drawing code.
 * Use this method if you need to change some OpenGL setup.
 * The corresponding method -unlockVideoSystem should be
 * called as soon as possible after this call.
 **/
- (void)lockVideoSystem;

/**
 * Unlocks the video system again
 **/
- (void)unlockVideoSystem;

/**
 * Creates a texture to be used within the video system
 **/
- (CVOpenGLTextureRef)createTextureFromImage:(CVPixelBufferRef)pixelBuffer;

/**
 * Returns a dictionary containing settings for the various video
 * modules
 **/
- (NSDictionary *)settings;

/**
 * Configures the video modules according to the settings
 * dictionary specified
 **/
- (void)setSettings:(NSDictionary *)settings;

/**
 * Returns an error description in case an error was
 * encountered
 **/
- (NSString *)errorDescription;

@end

#endif // __XM_VIDEO_MANAGER_H__
