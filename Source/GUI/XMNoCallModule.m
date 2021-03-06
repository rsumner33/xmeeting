/*
 * $Id: XMNoCallModule.m,v 1.57 2008/12/26 11:00:55 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"

#import "XMNoCallModule.h"

#import "XMApplicationController.h"
#import "XMCallAddressManager.h"
#import "XMSimpleAddressResource.h"
#import "XMAddressBookManager.h"
#import "XMPreferencesManager.h"
#import "XMH323Account.h"
#import "XMSIPAccount.h"
#import "XMLocation.h"
#import "XMApplicationFunctions.h"
#import "XMMainWindowController.h"
#import "XMLocalVideoView.h"

NSString *XMKey_NoCallModuleSelfViewStatus = @"XMeeting_NoCallModuleSelfViewStatus";
NSString *XMKey_NoCallModuleCallProtocol = @"XMeeting_NoCallModuleCallProtocol";
NSString *XMKey_NoCallModuleSize_SelfViewShown = @"XMeeting_NoCallModuleSize_SelfViewShown";
NSString *XMKey_NoCallModuleSize_SelfViewHidden = @"XMeeting_NoCallModuleSize_SelfViewHidden";

#define VIDEO_INSET 5

@interface XMNoCallModule (PrivateMethods)

- (void)_preferencesDidChange:(NSNotification *)notif;
- (void)_didChangeActiveLocation:(NSNotification *)notif;
- (void)_didStartSubsystemSetup:(NSNotification *)notif;
- (void)_didEndSubsystemSetup:(NSNotification *)notif;
- (void)_didUpdateNetworkAddresses:(NSNotification *)notif;
- (void)_didStartCallInitiation:(NSNotification *)notif;
- (void)_didStartCalling:(NSNotification *)notif;
- (void)_didNotStartCalling:(NSNotification *)notif;
- (void)_isRingingAtRemoteParty:(NSNotification *)notif;
- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;
- (void)_didChangeProtocolStatus:(NSNotification *)notif;
- (void)_didChangeGatekeeperStatus:(NSNotification *)notif;
- (void)_didChangeSIPRegistrationStatus:(NSNotification *)notif;
- (void)_addressBookDatabaseDidChange:(NSNotification *)notif;

- (void)_clearCallEndReason:(NSTimer *)timer;
- (void)_invalidateCallEndReasonTimer;

- (void)_updateStatusInformation:(NSString *)statusFieldString;
- (void)_setCallProtocol:(XMCallProtocol)callProtocol;
- (void)_setupVideoDisplay;

- (void)_windowWillMiniaturize:(NSNotification *)notif;
- (void)_windowDidDeminiaturize:(NSNotification *)notif;

@end

@implementation XMNoCallModule

- (id)init
{	
  uncompletedStringLength = 0;
  matchedAddresses = nil;
  completions = [[NSMutableArray alloc] initWithCapacity:10];
  
  doesShowSelfView = NO;
  isCalling = NO;
  
  return self;
}

- (void)dealloc
{
  [matchedAddresses release];
  [completions release];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];
}

- (void)awakeFromNib
{	
  // First, register for notifications
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver:self selector:@selector(_preferencesDidChange:) name:XMNotification_PreferencesManagerDidChangePreferences object:nil];
  [notificationCenter addObserver:self selector:@selector(_didChangeActiveLocation:) name:XMNotification_PreferencesManagerDidChangeActiveLocation object:nil];
  [notificationCenter addObserver:self selector:@selector(_didStartSubsystemSetup:) name:XMNotification_CallManagerDidStartSubsystemSetup object:nil];
  [notificationCenter addObserver:self selector:@selector(_didEndSubsystemSetup:) name:XMNotification_CallManagerDidEndSubsystemSetup object:nil];
  [notificationCenter addObserver:self selector:@selector(_didUpdateNetworkAddresses:) name:XMNotification_UtilsDidUpdateNetworkInformation object:nil];
  [notificationCenter addObserver:self selector:@selector(_didStartCallInitiation:) name:XMNotification_CallManagerDidStartCallInitiation object:nil];
  [notificationCenter addObserver:self selector:@selector(_didStartCalling:) name:XMNotification_CallManagerDidStartCalling object:nil];
  [notificationCenter addObserver:self selector:@selector(_didNotStartCalling:) name:XMNotification_CallManagerDidNotStartCalling object:nil];
  [notificationCenter addObserver:self selector:@selector(_isRingingAtRemoteParty:) name:XMNotification_CallManagerDidStartRingingAtRemoteParty object:nil];
  [notificationCenter addObserver:self selector:@selector(_didReceiveIncomingCall:) name:XMNotification_CallManagerDidReceiveIncomingCall object:nil];
  [notificationCenter addObserver:self selector:@selector(_didClearCall:) name:XMNotification_CallManagerDidClearCall object:nil];
  [notificationCenter addObserver:self selector:@selector(_didChangeProtocolStatus:) name:XMNotification_CallManagerDidChangeH323Status object:nil];
  [notificationCenter addObserver:self selector:@selector(_didChangeProtocolStatus:) name:XMNotification_CallManagerDidChangeSIPStatus object:nil];
  [notificationCenter addObserver:self selector:@selector(_didChangeGatekeeperStatus:) name:XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus object:nil];
  [notificationCenter addObserver:self selector:@selector(_didChangeSIPRegistrationStatus:) name:XMNotification_CallManagerDidChangeSIPRegistrationStatus object:nil];
  [notificationCenter addObserver:self selector:@selector(_addressBookDatabaseDidChange:) name:XMNotification_AddressBookManagerDidChangeDatabase object:nil];
  [notificationCenter addObserver:self selector:@selector(_windowWillMiniaturize:) name:NSWindowWillMiniaturizeNotification object:nil]; // don't know the window
  [notificationCenter addObserver:self selector:@selector(_windowDidDeminiaturize:) name:NSWindowDidDeminiaturizeNotification object:nil]; // don't known the window
		
  contentViewMinSizeWithSelfViewHidden = [contentView frame].size;
  contentViewMinSizeWithSelfViewShown = contentViewMinSizeWithSelfViewHidden;
  
  // substracting the space used by the self view
  contentViewMinSizeWithSelfViewHidden.height -= (VIDEO_INSET + [selfView frame].size.height);
  
  // the initial size equals the min size, if not specified in preferences
  NSString *selfViewHiddenSize = [[NSUserDefaults standardUserDefaults] stringForKey:XMKey_NoCallModuleSize_SelfViewHidden];
  NSString *selfViewShownSize = [[NSUserDefaults standardUserDefaults] stringForKey:XMKey_NoCallModuleSize_SelfViewShown];
  if (selfViewHiddenSize != nil) {
    contentViewSizeWithSelfViewHidden = NSSizeFromString(selfViewHiddenSize);
  } else {
    contentViewSizeWithSelfViewHidden = contentViewMinSizeWithSelfViewHidden;
  }
  if (selfViewShownSize != nil) {
    contentViewSizeWithSelfViewShown = NSSizeFromString(selfViewShownSize);
  } else {
    contentViewSizeWithSelfViewShown = contentViewMinSizeWithSelfViewShown;
  }
  
  XMCallProtocol initialCallProtocol = (XMCallProtocol)[[NSUserDefaults standardUserDefaults] integerForKey:XMKey_NoCallModuleCallProtocol];
  if (initialCallProtocol == XMCallProtocol_UnknownProtocol) {
    initialCallProtocol = XMCallProtocol_H323;
  }
  [self _setCallProtocol:initialCallProtocol];
  [self _preferencesDidChange:nil];
  
  // determining in which state we currently are
  if ([[XMCallManager sharedInstance] doesAllowModifications]) {
    [self _didEndSubsystemSetup:nil];
  } else {
    [self _didStartSubsystemSetup:nil];
  }
  
  BOOL showSelfView = [[NSUserDefaults standardUserDefaults] boolForKey:XMKey_NoCallModuleSelfViewStatus];
  
  if (showSelfView) {
    [self performSelector:@selector(toggleShowSelfView:) withObject:nil afterDelay:0.0];
  }
}

#pragma mark -
#pragma mark XMMainWindowModule methods

- (NSString *)name
{
  return @"NoCall";
}

- (NSView *)contentView
{
  if (contentView == nil) {
    [NSBundle loadNibNamed:@"NoCallModule" owner:self];
  }
  return contentView;
}

- (NSSize)contentViewSize
{
  // if not already done, this triggers the loading of the nib file
  [self contentView];
  
  if (doesShowSelfView) {
    return contentViewSizeWithSelfViewShown;
  } else {
    return contentViewSizeWithSelfViewHidden;
  }
}

- (NSSize)contentViewMinSize
{
  // if not already done, this triggers the loading of the nib file
  [self contentView];
  
  if (doesShowSelfView) {
    return contentViewMinSizeWithSelfViewShown;
  } else {
    return contentViewMinSizeWithSelfViewHidden;
  }
}

- (NSSize)contentViewMaxSize
{
  // if not already done, this triggers the loading of the nib file
  [self contentView];
  
  if (doesShowSelfView) {
    return NSMakeSize(5000, 5000);
  } else {
    return NSMakeSize(5000, contentViewMinSizeWithSelfViewHidden.height);
  }
}

- (NSSize)adjustResizeDifference:(NSSize)resizeDifference minimumHeight:(unsigned)minimumHeight
{
  if (doesShowSelfView == NO) {
    // also update the preferences
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize([contentView bounds].size) forKey:XMKey_NoCallModuleSize_SelfViewHidden];
    return resizeDifference;
  }
  
  NSSize size = [contentView bounds].size;
  
  unsigned usedHeight = contentViewSizeWithSelfViewHidden.height + VIDEO_INSET;
  
  int minimumVideoHeight = contentViewMinSizeWithSelfViewShown.height - usedHeight;
  int currentVideoHeight = (int)size.height - usedHeight;
  
  int availableWidth = (int)size.width + (int)resizeDifference.width - 2*VIDEO_INSET;
  int newHeight = currentVideoHeight + (int)resizeDifference.height;
  
  int calculatedWidthFromHeight = (int)XMGetVideoWidthForHeight(newHeight, XMVideoSize_CIF);
  int calculatedHeightFromWidth = (int)XMGetVideoHeightForWidth(availableWidth, XMVideoSize_CIF);
  
  if (calculatedHeightFromWidth <= minimumVideoHeight) {
    // set the height to the minimum height
    resizeDifference.height = minimumVideoHeight - currentVideoHeight;
  } else {
    if (calculatedWidthFromHeight < availableWidth) {
      // the height value takes precedence
      int widthDifference = availableWidth - calculatedWidthFromHeight;
      resizeDifference.width -= widthDifference;
    } else {
      // the width value takes precedence
      int heightDifference = newHeight - calculatedHeightFromWidth;
      resizeDifference.height -= heightDifference;
    }
  }
  
  // also update the preferences
  [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize([contentView bounds].size) forKey:XMKey_NoCallModuleSize_SelfViewShown];
  
  return resizeDifference;
}

- (void)becomeActiveModule
{
  [[contentView window] makeFirstResponder:callAddressField];
}

- (void)becomeInactiveModule
{
  if (doesShowSelfView) {
    contentViewSizeWithSelfViewShown = [contentView bounds].size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(contentViewSizeWithSelfViewShown) forKey:XMKey_NoCallModuleSize_SelfViewShown];
  } else {
    contentViewSizeWithSelfViewHidden = [contentView bounds].size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(contentViewSizeWithSelfViewHidden) forKey:XMKey_NoCallModuleSize_SelfViewHidden];
  }
}

- (void)beginFullScreen
{
}

- (void)endFullScreen
{
}

#pragma mark -
#pragma mark User Interface Methods

- (IBAction)toggleShowSelfView:(id)sender
{
  if (doesShowSelfView == NO) {
    contentViewSizeWithSelfViewHidden = [contentView bounds].size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(contentViewSizeWithSelfViewHidden) forKey:XMKey_NoCallModuleSize_SelfViewHidden];
    
    doesShowSelfView = YES;
    [[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfModule:self];
    
    [selfView setDrawsBorder:YES];
    [selfView display];
    
    [self _setupVideoDisplay];
    
    [contentView display]; // avoids 'wrong' GUI at launch time, 10.5.x
  } else {
    [selfView stopDisplayingLocalVideo];
    [selfView stopDisplayingNoVideo];
    [selfView setDrawsBorder:NO];
    
    contentViewSizeWithSelfViewShown = [contentView bounds].size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(contentViewSizeWithSelfViewShown) forKey:XMKey_NoCallModuleSize_SelfViewShown];
    
    doesShowSelfView = NO;
    [[XMMainWindowController sharedInstance] noteSizeValuesDidChangeOfModule:self];
  }
  
  [[NSUserDefaults standardUserDefaults] setBool:doesShowSelfView forKey:XMKey_NoCallModuleSelfViewStatus];
}

- (IBAction)showInfoInspector:(id)sender
{
  [(XMApplicationController *)[NSApp delegate] showInfoInspector];
}

- (IBAction)showTools:(id)sender
{
  [(XMApplicationController *)[NSApp delegate] showTools:self];
}

- (IBAction)showContacts:(id)sender
{
  [(XMApplicationController *)[NSApp delegate] showContacts:self];
}

- (IBAction)call:(id)sender
{
  if (isCalling == YES) {
    // we are calling someone but the call has not yet been established
    // therefore, we simply hang up the call again
    [[XMCallManager sharedInstance] clearActiveCall];
    [callButton setEnabled:NO];
    [statusField setStringValue:NSLocalizedString(@"Hangup...", @"")];
    [statusButton setImage:[NSImage imageNamed:@"status_yellow"]];
    
    return;
  }
  
  [callAddressField endEditing];
  id<XMCallAddress> callAddress = (id<XMCallAddress>)[callAddressField representedObject];
  if (callAddress == nil) {
    NSLog(@"ERROR: NO REPRESENTED OBJECT!");
    return;
  }
  
  // remember the call protocol used.
  XMCallProtocol protocolUsed = [[callAddress addressResource] callProtocol];
  [self _setCallProtocol:protocolUsed];
  
  [[XMCallAddressManager sharedInstance] makeCallToAddress:callAddress];
}

- (IBAction)changeActiveLocation:(id)sender
{
  unsigned selectedIndex = [locationsPopUpButton indexOfSelectedItem];
  [[XMPreferencesManager sharedInstance] activateLocationAtIndex:selectedIndex];
}

#pragma mark -
#pragma mark Call Address XMDatabaseComboBox Data Source Methods

- (NSArray *)databaseField:(XMDatabaseField *)databaseField
	  completionsForString:(NSString *)uncompletedString
	   indexOfSelectedItem:(unsigned *)indexOfSelectedItem
{	
  // if the user either enters h323: or sip:, we set the
  // call protocol accordingly and remove the prefix from
  // the address
  if ([uncompletedString hasPrefixCaseInsensitive:@"h323:"]) {
    [self _setCallProtocol:XMCallProtocol_H323];
    [databaseField setStringValue:[uncompletedString substringFromIndex:5]];
    return [NSArray array];
  } else if ([uncompletedString hasPrefixCaseInsensitive:@"sip:"]) {
    [self _setCallProtocol:XMCallProtocol_SIP];
    [databaseField setStringValue:[uncompletedString substringFromIndex:4]];
    return [NSArray array];
  }
  XMCallAddressManager *callAddressManager = [XMCallAddressManager sharedInstance];
  NSArray *originalMatchedAddresses;
  unsigned newUncompletedStringLength = [uncompletedString length];
  
  if (newUncompletedStringLength <= uncompletedStringLength) {
    // there may be more valid records than up to now, therefore
    // throwing the cache away.
    if (matchedAddresses != nil) {
      [matchedAddresses release];
      matchedAddresses = nil;
    }
  }
  
  if (matchedAddresses == nil) {
    // do a fresh search on the database
    originalMatchedAddresses = [[callAddressManager addressesMatchingString:uncompletedString] retain];
  } else {
    originalMatchedAddresses = matchedAddresses;
  }
  
  matchedAddresses = [[NSMutableArray alloc] initWithCapacity:[originalMatchedAddresses count]];
  [completions removeAllObjects];
  
  // All matched records have to be verified whether they actually contain the substring
  // at the correct place.
  unsigned i;
  unsigned count = [originalMatchedAddresses count];
  for (i = 0; i < count; i++) {
    id<XMCallAddress> callAddress = (id<XMCallAddress>)[originalMatchedAddresses objectAtIndex:i];
    NSString *completion = [callAddressManager completionStringForAddress:callAddress uncompletedString:uncompletedString];
    if (completion != nil) {
      [matchedAddresses addObject:callAddress];
      [completions addObject:completion];
    }
  }
  [originalMatchedAddresses release];
  uncompletedStringLength = newUncompletedStringLength;
  
  return completions;
}

- (id)databaseField:(XMDatabaseField *)databaseField representedObjectForCompletedString:(NSString *)completedString
{
  unsigned index = [completions indexOfObject:completedString];
  
  if (index == NSNotFound) {
    XMSimpleAddressResource *simpleAddressResource = [[[XMSimpleAddressResource alloc] initWithAddress:completedString callProtocol:currentCallProtocol] autorelease];
    return simpleAddressResource;
  }
  return [matchedAddresses objectAtIndex:index];
}

- (NSString *)databaseField:(XMDatabaseField *)databaseField displayStringForRepresentedObject:(id)representedObject
{
  NSString *displayString = [(id<XMCallAddress>)representedObject displayString];
  return displayString;
}

- (NSImage *)databaseField:(XMDatabaseField *)databaseField imageForRepresentedObject:(id)representedObject
{
  NSImage *image = [(id<XMCallAddress>)representedObject displayImage];
  return image;
}

- (NSArray *)imageOptionsForDatabaseField:(XMDatabaseField *)databaseField selectedIndex:(unsigned *)selectedIndex;
{
  id representedObject = [databaseField representedObject];
  
  if (representedObject != nil && [representedObject displayImage] != nil) {
    NSArray *records = [[XMCallAddressManager sharedInstance] alternativesForAddress:(id<XMCallAddress>)representedObject selectedIndex:selectedIndex];
    
    return records;
  } else {
    XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
    XMLocation *activeLocation = [preferencesManager activeLocation];
    BOOL enableH323 = [activeLocation enableH323];
    BOOL enableSIP = [activeLocation enableSIP];
    
    if (enableH323 && enableSIP) {
      if (currentCallProtocol == XMCallProtocol_H323) {
        *selectedIndex = 0;
      } else {
        *selectedIndex = 1;
      }
      return [NSArray arrayWithObjects:@"H.323", @"SIP", nil];
    } else if (enableH323) {
      *selectedIndex = 0;
      return [NSArray arrayWithObjects:@"H.323", nil];
    } else if (enableSIP) {
      *selectedIndex = 0;
      return [NSArray arrayWithObjects:@"SIP", nil];
    }
  }
  
  return [NSArray array];
}

- (void)databaseField:(XMDatabaseField *)databaseField userSelectedImageOption:(NSString *)imageOption index:(unsigned)index
{
  id representedObject = [databaseField representedObject];
  
  if (representedObject != nil && [representedObject displayImage] != nil) {
    id<XMCallAddress> alternative = [[XMCallAddressManager sharedInstance] alternativeForAddress:(id<XMCallAddress>)representedObject 
                                                                                         atIndex:index];
    [databaseField setRepresentedObject:alternative];
  } else if ([imageOption isEqualToString:@"H.323"]) {
    [self _setCallProtocol:XMCallProtocol_H323];
  } else {
    [self _setCallProtocol:XMCallProtocol_SIP];
  }
}

- (NSArray *)pulldownObjectsForDatabaseField:(XMDatabaseField *)databaseField
{
  XMCallAddressManager *callAddressManager = [XMCallAddressManager sharedInstance];
  return [callAddressManager allAddresses];
}

#pragma mark -
#pragma mark Notification Methods

- (void)_preferencesDidChange:(NSNotification *)notif
{
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  
  [locationsPopUpButton removeAllItems];
  [locationsPopUpButton addItemsWithTitles:[preferencesManager locationNames]];
  [locationsPopUpButton selectItemAtIndex:[preferencesManager indexOfActiveLocation]];
  
  XMLocation *activeLocation = [preferencesManager activeLocation];
  BOOL enableH323 = [activeLocation enableH323];
  BOOL enableSIP = [activeLocation enableSIP];
  
  if (enableH323 && !enableSIP) {
    [self _setCallProtocol:XMCallProtocol_H323];
  } else if (!enableH323 && enableSIP) {
    [self _setCallProtocol:XMCallProtocol_SIP];
  }
  
  BOOL mirrorSelfView = [preferencesManager showSelfViewMirrored];
  [selfView setLocalVideoMirrored:mirrorSelfView];
}

- (void)_didChangeActiveLocation:(NSNotification *)notif
{
  if (doesShowSelfView == YES) {
    [self _setupVideoDisplay];
  }
}

- (void)_didStartSubsystemSetup:(NSNotification *)notif
{
  [statusButton setHidden:YES];
  
  [busyIndicator startAnimation:self];
  [busyIndicator setHidden:NO];
  
  [statusField setStringValue:NSLocalizedString(@"XM_NO_CALL_SETUP_MESSAGE", @"")];
  
  [locationsPopUpButton setEnabled:NO];
  [callButton setEnabled:NO];
}

- (void)_didEndSubsystemSetup:(NSNotification *)notif
{
  [statusButton setHidden:NO];
  
  [busyIndicator stopAnimation:self];
  [busyIndicator setHidden:YES];
  
  [locationsPopUpButton setEnabled:YES];
  [callButton setEnabled:YES];
  
  [self _updateStatusInformation:nil];
  [self _invalidateCallEndReasonTimer];
}

- (void)_didUpdateNetworkAddresses:(NSNotification *)notif
{
  XMCallManager *callManager = [XMCallManager sharedInstance];
  
  // only update the status if the call manager allows notifications.
  // if the manager is doing a subsystem setup, the status will be
  // updated once the setup is complete
  if ([callManager doesAllowModifications]) {  
    [self _updateStatusInformation:nil];
  }
}

- (void)_didStartCallInitiation:(NSNotification *)notif
{
  // until XMNotification_CallManagerDidStartCalling is posted, we have to disable
  // the user GUI. Normally, only very little time passes befor this notification is
  // posted. However, in some cases, it may take some time (3-4) secs, in which the
  // user cannot clear the call
  
  id<XMCallAddress> activeCallAddress = [[XMCallAddressManager sharedInstance] activeCallAddress];
  if ([activeCallAddress displayImage] == nil) {
    [self _setCallProtocol:[[activeCallAddress addressResource] callProtocol]];
  }
  [callAddressField setRepresentedObject:activeCallAddress];
  [locationsPopUpButton setEnabled:NO];
  [callButton setEnabled:NO];
  [statusField setStringValue:NSLocalizedString(@"XM_NO_CALL_PREPARING_CALL", @"")];
  
  [self _invalidateCallEndReasonTimer];
}

- (void)_didStartCalling:(NSNotification *)notif
{
  [callButton setEnabled:YES];
  [callButton setImage:[NSImage imageNamed:@"hangup_24.tif"]];
  [callButton setAlternateImage:[NSImage imageNamed:@"hangup_24_down.tif"]];
  [statusField setStringValue:NSLocalizedString(@"XM_NO_CALL_CALLING", @"")];
  
  isCalling = YES;
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
  [locationsPopUpButton setEnabled:YES];
  [callButton setEnabled:YES];
  [self _updateStatusInformation:nil]; // information about this is handled within XMApplicationController
}

- (void)_isRingingAtRemoteParty:(NSNotification *)notif
{
  [statusField setStringValue:NSLocalizedString(@"XM_NO_CALL_RINGING", @"")];
}

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
  [locationsPopUpButton setEnabled:NO];
  [callButton setEnabled:NO];
  [statusField setStringValue:NSLocalizedString(@"XM_NO_CALL_INCOMING_CALL", @"")];
  
  [self _invalidateCallEndReasonTimer];
}

- (void)_didClearCall:(NSNotification *)notif
{
  [locationsPopUpButton setEnabled:YES];
  [callButton setEnabled:YES];
  [callButton setImage:[NSImage imageNamed:@"Call_24.tif"]];
  [callButton setAlternateImage:[NSImage imageNamed:@"Call_24_down.tif"]];
  
  // display the cause for the cleared call for some seconds
  XMCallInfo *callInfo = [[XMCallManager sharedInstance] recentCallAtIndex:0];
  XMCallEndReason callEndReason = [callInfo callEndReason];
  NSString *idleString = nil;
  if (callEndReason != XMCallEndReason_EndedByLocalUser &&
     callEndReason != XMCallEndReason_EndedByLocalBusy) {
    idleString = [[NSString alloc] initWithFormat:NSLocalizedString(@"XM_NO_CALL_IDLE_WITH_REASON", @""), XMCallEndReasonString(callEndReason)];
  }
  [self _updateStatusInformation:idleString];
  [idleString release];
  
  // causing the call clear reason to disappear after 10 seconds
  callEndReasonTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(_clearCallEndReason:)
                                                       userInfo:nil repeats:NO] retain];
  
  isCalling = NO;
}

- (void)_didChangeProtocolStatus:(NSNotification *)notif
{
  // only update the status window if the call manager allows modifications.
  // If the manager is doing a subsystem setup, the status will be updated
  // once the setup is complete
  if ([[XMCallManager sharedInstance] doesAllowModifications]) {
    [self _updateStatusInformation:nil];
  }
}

- (void)_didChangeGatekeeperStatus:(NSNotification *)notif
{
  // we're only interested in the situation when the gatekeeper registration
  // status changes without the user having triggered a subsystem setup
  if ([[XMCallManager sharedInstance] doesAllowModifications] == YES) {
    [self _updateStatusInformation:nil];
  }
}

- (void)_didChangeSIPRegistrationStatus:(NSNotification *)notif
{
  // we're only interested in the situation when the SIP registration
  // status changes without the user having triggered a subsystem setup
  if ([[XMCallManager sharedInstance] doesAllowModifications] == YES) {
    [self _updateStatusInformation:nil];
  }
}

- (void)_addressBookDatabaseDidChange:(NSNotification *)notif
{
  [callAddressField setRepresentedObject:nil];
}

#pragma mark -
#pragma mark Private Methods

- (void)_clearCallEndReason:(NSTimer *)timer
{
  if (timer != callEndReasonTimer) {
    // should never happen
    return;
  }
  if ([[XMCallManager sharedInstance] doesAllowModifications] == YES) {
    [self _updateStatusInformation:nil];
  }
  
  [self _invalidateCallEndReasonTimer];
}

- (void)_invalidateCallEndReasonTimer
{
  if (callEndReasonTimer != nil) {
    [callEndReasonTimer invalidate];
    [callEndReasonTimer release];
    callEndReasonTimer = nil;
  }
}

- (void)_updateStatusInformation:(NSString *)statusFieldString;
{
  XMUtils *utils = [XMUtils sharedInstance];
  XMCallManager *callManager = [XMCallManager sharedInstance];
  XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
  XMLocation *activeLocation = [preferencesManager activeLocation];
  
  // if no network interfaces are present, no calls can be made...
  NSArray *networkInterfaces = [utils networkInterfaces];
  unsigned interfaceCount = [networkInterfaces count];
  if (interfaceCount == 0) {
    NSString *statusString = NSLocalizedString(@"XM_NO_CALL_NO_ADDRESS", @"");
    [statusButton setImage:[NSImage imageNamed:@"status_red"]];
    [statusButton setToolTip:statusString];
    [statusField setStringValue:statusString];
    return;
  }
  
  // If no protocol is enabled, no calls can be made...
  BOOL isH323Enabled = [callManager isH323Enabled];
  BOOL isSIPEnabled = [callManager isSIPEnabled];
  BOOL enableH323 = [activeLocation enableH323];
  BOOL enableSIP = [activeLocation enableSIP];
  
  if (!isH323Enabled && !isSIPEnabled) {
    NSString *statusString = nil;
    
    if (!enableH323 && !enableSIP) {
      statusString = NSLocalizedString(@"XM_NO_CALL_NO_PROTOCOL", @"");
    } else if (enableH323 && enableSIP) {
      statusString = NSLocalizedString(@"XM_NO_CALL_PROTOCOL_FAILURE", @"");
    } else if (enableH323) {
      statusString = NSLocalizedString(@"XM_NO_CALL_H323_FAILURE", @"");
    } else {
      statusString = NSLocalizedString(@"XM_NO_CALL_SIP_FAILURE", @"");
    }
    
    [statusButton setImage:[NSImage imageNamed:@"status_red"]];
    [statusButton setToolTip:statusString];
    [statusField setStringValue:statusString];
    return;
  }

  // use default status if nothing was entered
  if (statusFieldString == nil) {
    statusFieldString = NSLocalizedString(@"XM_NO_CALL_IDLE", @"");
  }
  [statusField setStringValue:statusFieldString];
  
  // Determine status (yellow / green)
  NSMutableString *toolTipText = [[NSMutableString alloc] initWithCapacity:100];
  BOOL isYellowStatus = NO;
  if (enableH323 == YES) {
    if (isH323Enabled == NO) {
      isYellowStatus = YES;
      [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_H323_FAILURE", @"")];
    } else if ([activeLocation h323AccountTag] != 0) {
      NSString *gatekeeperName = [callManager gatekeeperName];
      if (gatekeeperName == nil) { // using a gatekeeper but failed to register
        isYellowStatus = YES;
        [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_GK_FAILURE", @"")];
      } else {
        [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_GK_OK", @"")];
      }
    } else {
      [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_NO_GK", @"")];
    }
  }
  
  if (enableSIP == YES) {
    if (isSIPEnabled == NO) {
      isYellowStatus = YES;
      [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_SIP_FAILURE", @"")];
    } else {
      unsigned count = [[activeLocation sipAccountTags] count];
      
      if (count != 0) {
        unsigned registrationCount = [callManager sipRegistrationCount];
        if (registrationCount != count) {
          isYellowStatus = YES;
          if (count == 1) {
            [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_SIP_REG_FAILURE", @"")];
          } else if (registrationCount == 0) {
            [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_SIP_REG_FAILURE_ALL", @"")];
          } else {
            [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_SIP_REG_FAILURE_SOME", @"")];
          }
        } else {
          if (count == 1) {
            [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_SIP_REG_OK", @"")];
          } else {
            [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_SIP_REG_OK_MULTIPLE", @"")];
          }
        }
      } else {
        [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_SIP_NO_REG", @"")];
      }
    }
  }
  
  if (isYellowStatus == YES) {
    [statusButton setImage:[NSImage imageNamed:@"status_yellow"]];
  } else {
    [statusButton setImage:[NSImage imageNamed:@"status_green"]];
  }
  
  // appending the network addresses to the tool tip
  NSString *publicAddress = nil;
  unsigned publicAddressIndex = NSNotFound;
  publicAddress = [utils publicAddress];
		
  if (publicAddress != nil) {
    for (unsigned i = 0; i < interfaceCount; i++) {
      XMNetworkInterface *iface = (XMNetworkInterface *)[networkInterfaces objectAtIndex:i];
      if ([[iface ipAddress] isEqualToString:publicAddress]) {
        publicAddressIndex = i;
        break;
      }
    }
  }
  
  [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_NETWORK_ADDRESSES", @"")];
  
  for (unsigned i = 0; i < interfaceCount; i++) {
    NSString *address = (NSString *)[[networkInterfaces objectAtIndex:i] name];
    [toolTipText appendString:@"\n"];
    [toolTipText appendString:address];
    
    if (i == publicAddressIndex) {
      [toolTipText appendString:NSLocalizedString(@"XM_EXTERNAL_ADDRESS_SUFFIX", @"")];
    }
  }
  
  if (publicAddressIndex == NSNotFound) {
    if (publicAddress == nil) {
      [toolTipText appendString:NSLocalizedString(@"XM_NO_CALL_TOOLTIP_NO_EXTERNAL_ADDRESS", @"")];
    } else {
      [toolTipText appendString:@"\n"];
      [toolTipText appendString:publicAddress];
      [toolTipText appendString:NSLocalizedString(@"XM_EXTERNAL_ADDRESS_SUFFIX", @"")];
    }
  }
  
  [statusButton setToolTip:toolTipText];
  [toolTipText release];
}

- (void)_setupVideoDisplay
{
  if ([[[XMPreferencesManager sharedInstance] activeLocation] enableVideo] == YES) {
    [selfView startDisplayingLocalVideo];
  } else {
    [selfView setNoVideoImage:[NSImage imageNamed:@"no_video_screen"]];
    [selfView startDisplayingNoVideo];
  }
}

- (void)_setCallProtocol:(XMCallProtocol)callProtocol
{
  if (currentCallProtocol == callProtocol) {
    return;
  }
  currentCallProtocol = callProtocol;
  
  if (callProtocol == XMCallProtocol_H323) {
    [callAddressField setDefaultImage:[NSImage imageNamed:@"DefaultURL_H323"]];
  } else if (callProtocol == XMCallProtocol_SIP) {
    [callAddressField setDefaultImage:[NSImage imageNamed:@"DefaultURL_SIP"]];
  }
  
  id<XMCallAddress> representedObject = (id<XMCallAddress>)[callAddressField representedObject];
  
  if ([representedObject isKindOfClass:[XMSimpleAddressResource class]]) {
    XMSimpleAddressResource *resource = (XMSimpleAddressResource *)representedObject;
    [resource setCallProtocol:callProtocol];
  } else if (representedObject != nil) {
    XMAddressResource *res = [representedObject addressResource];
    XMSimpleAddressResource *resource = [[XMSimpleAddressResource alloc] initWithAddress:[res address] callProtocol:callProtocol];
    [resource setDisplayString:[representedObject displayString]];
    [resource setDisplayImage:[representedObject displayImage]];
    [callAddressField setRepresentedObject:resource];
    [resource release];
  }
  
  [[NSUserDefaults standardUserDefaults] setInteger:(int)currentCallProtocol forKey:XMKey_NoCallModuleCallProtocol];
}

- (void)_windowWillMiniaturize:(NSNotification *)notif
{
  // ensure the notification is of importance
  if ([notif object] == [contentView window]) {
    // ensure the busy indicator is stopped, otherwise there might be ugly artefacts in the GUI (10.5.x)
    [busyIndicator stopAnimation:self];
    [busyIndicator setHidden:YES];
  }
}

- (void)_windowDidDeminiaturize:(NSNotification *)notif
{
  // ensure the notification is of importance
  if ([notif object] == [contentView window]) {
    // restart the busy indicator if needed
    if ([[XMCallManager sharedInstance] doesAllowModifications] == NO) {
      [busyIndicator startAnimation:self];
      [busyIndicator setHidden:NO];
    }
  }
}

@end
