/*
 * $Id: XMApplicationController.m,v 1.23 2006/03/17 13:20:49 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMApplicationController.h"

#import "XMeeting.h"
#import "XMPreferencesManager.h"
#import "XMAddressBookCallAddressProvider.h"
#import "XMCallHistoryCallAddressProvider.h"

#import "XMMainWindowController.h"
#import "XMNoCallModule.h"
#import "XMInCallModule.h"

#import "XMInspectorController.h"

#import "XMInfoModule.h"
#import "XMStatisticsModule.h"
#import "XMCallHistoryModule.h"

#import "XMLocalAudioVideoModule.h"

#import "XMAddressBookModule.h"

//#import "XMZeroConfModule.h"
//#import "XMDialPadModule.h"
//#import "XMTextChatModule.h"

#import "XMPreferencesWindowController.h"

#import "XMSetupAssistantManager.h"

@interface XMApplicationController (PrivateMethods)

- (void)_didReceiveIncomingCall:(NSNotification *)notif;
- (void)_didEstablishCall:(NSNotification *)notif;
- (void)_didClearCall:(NSNotification *)notif;

// handle errors
- (void)_didNotStartCalling:(NSNotification *)notif;
- (void)_didNotEnableH323:(NSNotification *)notif;
- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif;
- (void)_didNotEnableSIP:(NSNotification *)notif;
- (void)_didNotRegisterAtRegistrar:(NSNotification *)notif;

// terminating the application
- (void)_frameworkClosed:(NSNotification *)notif;

// displaying dialogs
- (void)_displayIncomingCall;
- (void)_displayCallStartFailed;
- (void)_displayEnablingH323FailedAlert;
- (void)_displayGatekeeperRegistrationFailedAlert;
- (void)_displayEnableingSIPFailedAlert;
- (void)_displayRegistrarRegistrationFailedAlert;

// validating menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

- (void)_showSetupAssistant;
- (void)_setupApplication:(NSArray *)locations;

@end

@implementation XMApplicationController

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	// all setup is done in -applicationDidFinishLaunching
	// in order to avoid problems with the XMeeting framework's runtime
	// engine
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
	// Initialize the framework
	XMInitFramework();
	
	// registering for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(_didReceiveIncomingCall:)
							   name:XMNotification_CallManagerDidReceiveIncomingCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didEstablishCall:)
							   name:XMNotification_CallManagerDidEstablishCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didClearCall:)
							   name:XMNotification_CallManagerDidClearCall object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotStartCalling:)
							   name:XMNotification_CallManagerDidNotStartCalling object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotEnableH323:)
							   name:XMNotification_CallManagerDidNotEnableH323 object:nil];
	[notificationCenter addObserver:self selector:@selector(_didNotRegisterAtGatekeeper:)
							   name:XMNotification_CallManagerDidNotRegisterAtGatekeeper object:nil];
	[notificationCenter addObserver:self selector:@selector(_frameworkDidClose:)
							   name:XMNotification_FrameworkDidClose object:nil];
	
	// depending on wheter preferences are in the system, the setup assistant is shown or not.
	if([XMPreferencesManager doesHavePreferences] == YES)
	{
		[self performSelector:@selector(_setupApplication:) withObject:nil afterDelay:0.0];
	}
	else
	{
		[self performSelector:@selector(_showSetupAssistant) withObject:nil afterDelay:0.0];
	}
}

- (void)dealloc
{
	[noCallModule release];
	[inCallModule release];
	
	[infoModule release];
	[statisticsModule release];
	[callHistoryModule release];
	
	[localAudioVideoModule release];
	
	[addressBookModule release];
	
	//[zeroConfModule release];
	//[dialPadModule release];
	//[textChatModule release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark Action Methods

- (IBAction)showPreferences:(id)sender
{
	[[XMPreferencesWindowController sharedInstance] showPreferencesWindow];
}

- (IBAction)updateDeviceLists:(id)sender
{
	[[XMVideoManager sharedInstance] updateInputDeviceList];
}

- (IBAction)retryGatekeeperRegistration:(id)sender
{
	[[XMCallManager sharedInstance] retryGatekeeperRegistration];
}

- (IBAction)showInspector:(id)sender
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Inspector] show];
}

- (IBAction)showTools:(id)sender
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Tools] show];
}

- (IBAction)showContacts:(id)sender
{
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Contacts] show];
}


#pragma mark -
#pragma mark NSApplication delegate methods

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	XMCloseFramework();
	
	[[XMPreferencesManager sharedInstance] synchronize];
	
	// wait for the FrameworkDidClose notification before terminating.
	return NSTerminateLater;
}

#pragma mark Notification Methods

- (void)_didReceiveIncomingCall:(NSNotification *)notif
{
	
	[self performSelector:@selector(_displayIncomingCall) withObject:nil afterDelay:0.0];
}

- (void)_didEstablishCall:(NSNotification *)notif
{
	[[XMMainWindowController sharedInstance] showModule:inCallModule];
}

- (void)_didClearCall:(NSNotification *)notif
{	
	if(incomingCallAlert != nil)
	{
		[NSApp abortModal];
	}
	[[XMMainWindowController sharedInstance] showModule:noCallModule];
}

- (void)_didNotStartCalling:(NSNotification *)notif
{
	// by delaying the display of the callStartFailed message on screen, we allow
	// that all observers of this notification have received the notification
	[self performSelector:@selector(_displayCallStartFailed) withObject:nil afterDelay:0.0];
}

- (void)_didNotEnableH323:(NSNotification *)notif
{
	[self performSelector:@selector(_displayEnableH323FailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_didNotRegisterAtGatekeeper:(NSNotification *)notif
{
	[self performSelector:@selector(_displayGatekeeperRegistrationFailedAlert) withObject:nil afterDelay:0.0];
}

- (void)_frameworkDidClose:(NSNotification *)notif
{
	// Now it's time to terminate the application
	[NSApp replyToApplicationShouldTerminate:YES];
}

#pragma mark Displaying Alerts

- (void)_displayIncomingCall
{
	incomingCallAlert = [[NSAlert alloc] init];
	
	[incomingCallAlert setMessageText:NSLocalizedString(@"Incoming Call", @"")];
	
	NSString *informativeTextFormat = NSLocalizedString(@"Incoming call from \"%@\"\nTake call or not?", @"");
	XMCallInfo *activeCall = [[XMCallManager sharedInstance] activeCall];
	NSString *remoteName = [activeCall remoteName];
	
	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, remoteName];
	[incomingCallAlert setInformativeText:informativeText];
	[informativeText release];
	
	[incomingCallAlert setAlertStyle:NSInformationalAlertStyle];
	[incomingCallAlert addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
	[incomingCallAlert addButtonWithTitle:NSLocalizedString(@"No", @"")];
	
	int result = [incomingCallAlert runModal];
	
	if(result == NSAlertFirstButtonReturn)
	{
		[[XMCallManager sharedInstance] acceptIncomingCall];
	}
	else if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] rejectIncomingCall];
	}
	
	[incomingCallAlert release];
	incomingCallAlert = nil;
	

}

- (void)_displayCallStartFailed
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"Call failed", @"")];
	
	NSString *informativeTextFormat = NSLocalizedString(@"Unable to call ADDRESS. (%@)", @"");
	NSString *failReasonText;
	
	XMCallStartFailReason failReason = [[XMCallManager sharedInstance] callStartFailReason];
	
	switch(failReason)
	{
		case XMCallStartFailReason_ProtocolNotEnabled:
			failReasonText = NSLocalizedString(@"Protocol not enabled", @"");
			break;
		case XMCallStartFailReason_GatekeeperUsedButNotSpecified:
			failReasonText = NSLocalizedString(@"Address uses a gatekeeper but no gatekeeper is specified in the active location", @"");
			break;
		default:
			failReasonText = NSLocalizedString(@"Unknown reason", @"");
			break;
	}
	
	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, failReasonText];
	[alert setInformativeText:informativeText];
	[informativeText release];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	
	[alert runModal];
	
	[alert release];
}

- (void)_displayEnableH323FailedAlert
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	[alert setMessageText:NSLocalizedString(@"Enabling H.323 Failed", @"")];
	[alert setInformativeText:NSLocalizedString(@"Unable to enable the H.323 subsystem.\nThere is probably another H.323 application running.\nYou will not be able to make H.323 calls", @"")];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
	
	int result = [alert runModal];
	
	if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] retryEnableH323];
	}
	
	[alert release];
}

- (void)_displayGatekeeperRegistrationFailedAlert
{
	NSAlert *alert = [[NSAlert alloc] init];
	
	XMCallManager *callManager = [XMCallManager sharedInstance];
	XMGatekeeperRegistrationFailReason failReason = [callManager gatekeeperRegistrationFailReason];
	NSString *reasonText;
	NSString *suggestionText;
	
	switch(failReason)
	{
		/*case XMGatekeeperRegistrationFailReason_NoGatekeeperSpecified:
			reasonText = NSLocalizedString(@"no gatekeeper specified", @"");
			suggestionText = NSLocalizedString(@"Please specify a gatekeeper in preferences.", @"");
			break;*/
		case XMGatekeeperRegistrationFailReason_GatekeeperNotFound:
			reasonText = NSLocalizedString(@"gatekeeper not found", @"");
			suggestionText = NSLocalizedString(@"Please check your internet connection.", @"");
			break;
		case XMGatekeeperRegistrationFailReason_RegistrationReject:
			reasonText = NSLocalizedString(@"gatekeeper rejected registration", @"");
			suggestionText = NSLocalizedString(@"Please check your gatekeeper settings.", @"");
			break;
		default:
			reasonText = NSLocalizedString(@"unknown failure", @"");
			suggestionText = @"";
			break;
	}
	
	[alert setMessageText:NSLocalizedString(@"Gatekeeper Registration Failed", @"")];
	NSString *informativeTextFormat = NSLocalizedString(@"Unable to register at gatekeeper. (%@) You will not be able \
	to use phone numbers when making a call. %@", @"");
	

	NSString *informativeText = [[NSString alloc] initWithFormat:informativeTextFormat, reasonText, suggestionText];
	[alert setInformativeText:informativeText];
	[informativeText release];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
	
	int result = [alert runModal];
	
	if(result == NSAlertSecondButtonReturn)
	{
		[[XMCallManager sharedInstance] retryGatekeeperRegistration];
	}
	
	[alert release];
}

#pragma mark -
#pragma mark Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if([menuItem tag] == 311)
	{
		XMCallManager *callManager = [XMCallManager sharedInstance];
		
		if([callManager gatekeeperRegistrationFailReason] != XMGatekeeperRegistrationFailReason_NoFailure)
		{
			return YES;
		}
		return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Private Methods

- (void)_showSetupAssistant
{
	[[XMSetupAssistantManager sharedInstance] runFirstApplicationLaunchAssistantWithDelegate:self
																			  didEndSelector:@selector(_setupApplication:)];
}

- (void)_setupApplication:(NSArray *)locations
{		
	// registering the call address providers
	[[XMCallHistoryCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	[[XMAddressBookCallAddressProvider sharedInstance] setActiveCallAddressProvider:YES];
	
	noCallModule = [[XMNoCallModule alloc] init];
	inCallModule = [[XMInCallModule alloc] init];
	NSArray *mainWindowModules = [[NSArray alloc] initWithObjects:noCallModule, inCallModule, nil];
	[[XMMainWindowController sharedInstance] setModules:mainWindowModules];
	[mainWindowModules release];
	
	infoModule = [[XMInfoModule alloc] init];
	[infoModule setTag:XMInspectorControllerTag_Inspector];
	statisticsModule = [[XMStatisticsModule alloc] init];
	[statisticsModule setTag:XMInspectorControllerTag_Inspector];
	callHistoryModule = [[XMCallHistoryModule alloc] init];
	[callHistoryModule setTag:XMInspectorControllerTag_Inspector];
	NSArray *inspectorModules = [[NSArray alloc] initWithObjects:infoModule, statisticsModule, callHistoryModule, nil];
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Inspector] setModules:inspectorModules];
	[inspectorModules release];
	
	localAudioVideoModule = [[XMLocalAudioVideoModule alloc] init];
	[localAudioVideoModule setTag:XMInspectorControllerTag_Tools];
	NSArray *toolsModules = [[NSArray alloc] initWithObjects:localAudioVideoModule, nil];
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Tools] setModules:toolsModules];
	[toolsModules release];
	
	addressBookModule = [[XMAddressBookModule alloc] init];
	[addressBookModule setTag:XMInspectorControllerTag_Contacts];
	NSArray *contactsModules = [[NSArray alloc] initWithObjects:addressBookModule, nil];
	[[XMInspectorController inspectorWithTag:XMInspectorControllerTag_Contacts] setModules:contactsModules];
	[contactsModules release];
	
	// start fetching the external address
	XMUtils *utils = [XMUtils sharedInstance];
	[utils startFetchingExternalAddress];
	
	// causing the PreferencesManager to activate the active location
	// by calling XMCallManager -setActivePreferences:
	XMPreferencesManager *preferencesManager = [XMPreferencesManager sharedInstance];
	[preferencesManager setLocations:locations];
	if([locations count] != 0)
	{
		[preferencesManager synchronizeAndNotify];
	}
	
	// show the main window
	[[XMMainWindowController sharedInstance] showMainWindow];
	
	// start grabbing from the video sources
	[[XMVideoManager sharedInstance] startGrabbing];
	
	incomingCallAlert = nil;
}

@end
