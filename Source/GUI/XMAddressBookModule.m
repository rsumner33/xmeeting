/*
 * $Id: XMAddressBookModule.m,v 1.6 2005/08/24 22:29:39 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <AddressBook/AddressBook.h>
#import <AddressBook/AddressBookUI.h>

#import "XMeeting.h"
#import "XMAddressBookModule.h"
#import "XMMainWindowController.h"
#import "XMCallAddressManager.h"

NSString *XMAddressBookPeoplePickerViewAutosaveName = @"XMeetingAddressBookPeoplePickerView";

@interface ABPerson (XMCallAddressMethods)

- (id<XMCallAddressProvider>)provider;
- (XMURL *)url;
- (NSString *)displayString;
- (NSString *)displayImage;

@end

@interface XMAddressBookModule (PrivateMethods)

- (void)_recordSelectionDidChange:(NSNotification *)notif;

- (void)_editPerson:(ABPerson<XMAddressBookRecord> *)person;
- (void)_validateButtons;

- (void)_validateEditRecordGUI:(BOOL)enableGatekeeperPart;
- (void)_validateEditOKButton:(BOOL)checkGatekeeperPart;

@end

@implementation XMAddressBookModule

- (id)init
{
	[[XMMainWindowController sharedInstance] addAdditionModule:self];
}

- (void)dealloc
{
	[nibLoader release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	contentViewSize = [contentView frame].size;
	
	[addressBookView setAutosaveName:XMAddressBookPeoplePickerViewAutosaveName];
	[addressBookView setTarget:self];
	[addressBookView setNameDoubleAction:@selector(editURL:)];
	
	// since the XMeeting framework stores the full XMURL string which is not very well
	// human readable, we store a more human readable form under the
	// XMAddressBookHumanReadableCallAddressProperty key. This way, we maintain
	// both a more human readable representation to display in the PeoplePickerView and
	// the complete call URL used for the XMeeting framework
	[addressBookView addProperty:XMAddressBookProperty_HumanReadableCallURLRepresentation];
	[addressBookView setColumnTitle:@"Call Address" forProperty:XMAddressBookProperty_HumanReadableCallURLRepresentation];
	
	// registering some notification
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(_recordSelectionDidChange:)
												 name:ABPeoplePickerNameSelectionDidChangeNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_recordSelectionDidChange:)
												 name:ABPeoplePickerGroupSelectionDidChangeNotification
											   object:nil];
	
	// validating the buttons
	[self _validateButtons];
	
}

- (NSString *)name
{
	return @"Address Book";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"AddressBook"];
}

- (NSView *)contentView
{
	if(nibLoader == nil)
	{
		nibLoader = [[NSNib alloc] initWithNibNamed:@"AddressBook" bundle:nil];
		[nibLoader instantiateNibWithOwner:self topLevelObjects:nil];
	}
	
	return contentView;
}

- (NSSize)contentViewSize
{
	// if not already done, causing the nib file to load
	[self contentView];
	
	return contentViewSize;
}

- (void)becomeActiveModule
{
}

- (void)becomeInactiveModule
{
}

#pragma mark Action Methods

- (IBAction)call:(id)sender
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	if([selectedRecords count] == 0)
	{
		return;
	}
	
	ABRecord *record = [selectedRecords objectAtIndex:0];
	
	[[XMCallAddressManager sharedInstance] makeCallToAddress:(id<XMCallAddress>)record];
}

- (IBAction)editURL:(id)sender
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	
	if([selectedRecords count] == 0)
	{
		return;
	}
	
	[self _editPerson:(ABPerson<XMAddressBookRecord> *)[selectedRecords objectAtIndex:0]];
}

- (IBAction)newRecord:(id)sender
{
	[firstNameField setStringValue:@""];
	[lastNameField setStringValue:@""];
	[organizationField setStringValue:@""];
	[isOrganizationSwitch setState:NSOffState];
	
	[NSApp beginSheet:newRecordSheet modalForWindow:[contentView window] modalDelegate:nil
	   didEndSelector:NULL contextInfo:NULL];
	[newRecordSheet makeFirstResponder:firstNameField];
}

- (IBAction)launchAddressBook:(id)sender
{
	[addressBookView editInAddressBook:sender];
}

- (IBAction)callTypeSelected:(id)sender
{
	BOOL enableGatekeeperPart = ([callTypePopUp indexOfSelectedItem] == 1);
	[self _validateEditRecordGUI:enableGatekeeperPart];
	[self _validateEditOKButton:enableGatekeeperPart];
}

- (IBAction)gatekeeperTypeChanged:(id)sender
{
	[self _validateEditOKButton:YES];
}

- (IBAction)endEditRecordSheet:(id)sender
{	
	if(sender == deleteButton)
	{
		[editedRecord setCallURL:nil];
	}
	else if(sender == okButton)
	{
		if(!editedURL)
		{
			editedURL = [[XMGeneralPurposeURL alloc] init];
		}
		
		NSString *addressPart;
		NSString *gatekeeperHost = nil;
		
		if([callTypePopUp indexOfSelectedItem] == 0)
		{ 
			[editedURL setValue:nil forKey:XMKey_PreferencesUseGatekeeper];
			
			addressPart = [directCallAddressField stringValue];
		}
		else
		{
			NSNumber *number = [[NSNumber alloc] initWithBool:YES];
			[editedURL setValue:number forKey:XMKey_PreferencesUseGatekeeper];
			[number release];
			
			addressPart = [gatekeeperCallAddressField stringValue];
			
			if([[gatekeeperMatrix selectedCell] tag] == 1)
			{
				gatekeeperHost = [gatekeeperHostField stringValue];
			}
		}
		
		[editedURL setAddress:addressPart];
		[editedURL setValue:gatekeeperHost forKey:XMKey_PreferencesGatekeeperAddress];

		[editedRecord setCallURL:editedURL];
		
		// in case this is a new record, we add it. If the record is already contained,
		// this method does nothing
		XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
		[addressBookManager addRecord:editedRecord];
	}
	
	[NSApp endSheet:editRecordSheet];
	[editRecordSheet orderOut:self];
	
	//workaround for buggy behaviour of people picker view
	[addressBookView selectRecord:editedRecord byExtendingSelection:NO];
	
	[editedRecord release];
	[editedURL release];
	editedRecord = nil;
	editedURL = nil;
	
	[self _validateButtons];
}

- (IBAction)addNewRecord:(id)sender
{
	XMAddressBookManager *addressBookManager = [XMAddressBookManager sharedInstance];
	ABPerson *record = [addressBookManager createRecordWithFirstName:[firstNameField stringValue]
														   lastName:[lastNameField stringValue]
														companyName:[organizationField stringValue]
														  isCompany:([isOrganizationSwitch state] == NSOnState)
															callURL:nil];
	
	[self cancelNewRecord:self];
	
	[self _editPerson:record];
}

- (IBAction)cancelNewRecord:(id)sender
{
	[NSApp endSheet:newRecordSheet];
	[newRecordSheet orderOut:self];
}

#pragma mark Delegate Methods

- (void)controlTextDidChange:(NSNotification *)notif
{
	NSObject *object = [notif object];
	BOOL checkGatekeeperPart = YES;
	
	if(object == directCallAddressField)
	{
		checkGatekeeperPart = NO;
	}
	else if(object == gatekeeperHostField)
	{
		[gatekeeperMatrix selectCellWithTag:1];
	}
	[self _validateEditOKButton:checkGatekeeperPart];
}

#pragma mark Private Methods

- (void)_recordSelectionDidChange:(NSNotification *)notif
{
	[self _validateButtons];
}

- (void)_editPerson:(ABPerson<XMAddressBookRecord> *)record
{
	// The name for this record is determined from AdressBook:
	// If the record is a person, the preferred name scheme is 
	// "(FirstName) (LastName)".
	// If for example only the first name is present, only 
	// the first name is displayed. If no first name or last name
	// are present, the company name is used if possible.
	// in case of a company, the company name is taken as the first
	// choice.
	NSString *recordDisplayName = [record displayName];
	[recordNameField setStringValue:recordDisplayName];
	
	BOOL enableDeleteButton;
	BOOL enableGatekeeperPart;
	unsigned urlTypeIndex;
	NSString *directCallAddress;
	NSString *gatekeeperCallAddress;
	unsigned gatekeeperTypeIndex;
	NSString *gatekeeperAddress;
	
	editedURL = (XMGeneralPurposeURL *)[[record callURL] retain];
	
	if(!editedURL)
	{
		enableDeleteButton = NO;
		enableGatekeeperPart = NO;
		urlTypeIndex = 0;
		directCallAddress = @"";
		gatekeeperCallAddress = @"";
		gatekeeperTypeIndex = 0;
		gatekeeperAddress = @"";
	}
	else
	{
		NSString *address = [editedURL address];
		NSNumber *number = [editedURL valueForKey:XMKey_PreferencesUseGatekeeper];
		
		if(number && [number boolValue] == YES)
		{
			enableGatekeeperPart = YES;
		}
			
		enableDeleteButton = YES;
			
		if(enableGatekeeperPart)
		{
			urlTypeIndex = 1;
			directCallAddress = @"";
			gatekeeperCallAddress = address;
			
			gatekeeperAddress = [editedURL valueForKey:XMKey_PreferencesGatekeeperUsername];
			if(gatekeeperAddress)
			{
				gatekeeperTypeIndex = 1;
			}
			else
			{
				gatekeeperTypeIndex = 0;
				gatekeeperAddress = @"";
			}
		}
		else
		{
			urlTypeIndex = 0;
			directCallAddress = address;
			gatekeeperCallAddress = @"";
			gatekeeperTypeIndex = 0;
			gatekeeperAddress = @"";
		}
	}
		  
	[deleteButton setEnabled:enableDeleteButton];
	[self _validateEditRecordGUI:enableGatekeeperPart];
	[callTypePopUp selectItemAtIndex:urlTypeIndex];
	[directCallAddressField setStringValue:directCallAddress];
	[gatekeeperCallAddressField setStringValue:gatekeeperCallAddress];
	[gatekeeperMatrix selectCellWithTag:gatekeeperTypeIndex];
	[gatekeeperHostField setStringValue:gatekeeperAddress];
	
	[self _validateEditOKButton:enableGatekeeperPart];
	
	[NSApp beginSheet:editRecordSheet modalForWindow:[contentView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	
	editedRecord = [record retain];
}

- (void)_validateButtons
{
	NSArray *selectedRecords = [addressBookView selectedRecords];
	ABPerson<XMAddressBookRecord> *person;
	
	BOOL enableCallButton = YES;
	BOOL enableEditButton = YES;
	
	if([selectedRecords count] == 0)
	{
		enableEditButton = NO;
		enableCallButton = NO;
	}
	else
	{
		person = (ABPerson<XMAddressBookRecord> *)[selectedRecords objectAtIndex:0];
		
		if([person isValid] == NO)
		{
			enableCallButton = NO;
		}
	}
	
	[callButton setEnabled:enableCallButton];
	[editButton setEnabled:enableEditButton];
}

- (void)_validateEditRecordGUI:(BOOL)enableGatekeeperPart
{
	NSColor *directColor;
	NSColor *gatekeeperColor;
	NSTextField *newFirstResponder;
	
	if(enableGatekeeperPart)
	{
		directColor = [NSColor disabledControlTextColor];
		gatekeeperColor = [NSColor controlTextColor];
		newFirstResponder = gatekeeperCallAddressField;
	}
	else
	{
		directColor = [NSColor controlTextColor];
		gatekeeperColor = [NSColor disabledControlTextColor];
		newFirstResponder = directCallAddressField;
	}
	[directCallAddressLabel setTextColor:directColor];
	[directCallAddressField setEnabled:!enableGatekeeperPart];
	
	[gatekeeperCallAddressLabel setTextColor:gatekeeperColor];
	[gatekeeperCallAddressField setEnabled:enableGatekeeperPart];
	[gatekeeperMatrix setEnabled:enableGatekeeperPart];
	[gatekeeperHostField setEnabled:enableGatekeeperPart];
	
	[editRecordSheet makeFirstResponder:newFirstResponder];
}

- (void)_validateEditOKButton:(BOOL)checkGatekeeperPart
{
	BOOL enableOKButton = YES;
	
	if(checkGatekeeperPart)
	{
		if(([[gatekeeperCallAddressField stringValue] isEqualToString:@""]) ||
		   (([[gatekeeperMatrix selectedCell] tag] == 1) && ([[gatekeeperHostField stringValue] isEqualToString:@""])))
		{
			enableOKButton = NO;
		}

	}
	else
	{
		if([[directCallAddressField stringValue] isEqualToString:@""])
		{
			enableOKButton = NO;
		}
	}
	
	[okButton setEnabled:enableOKButton];
}

@end

@implementation ABPerson (XMCallAddressMethods)

- (id<XMCallAddressProvider>)provider
{
	return nil;
}

- (XMURL *)url
{
	return [(ABPerson<XMAddressBookRecord> *)self callURL];
}

- (NSString *)displayString
{
	return [(ABPerson<XMAddressBookRecord> *)self displayName];
}

- (NSString *)displayImage
{
	return [NSImage imageNamed:@"AddressBook"];
}

@end