//
//  ContactListViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import	<AddressBookUI/AddressBookUI.h>

#import "ContactListViewController.h"
#import "Contact.h"

@implementation ContactListViewController

@synthesize contacts;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style])
	{
		self.title = @"Contact List";
    }
    return self;
}

- (void) setEditing:(BOOL)e animated:(BOOL)animated
{
	if( e )
	{
		self.tableView.allowsSelectionDuringEditing = YES;
		// Eanble the Add button while editing
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showPeoplePicker)];
	}
	else
		self.navigationItem.rightBarButtonItem = nil;

	[super setEditing:e animated:animated];
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
	const NSInteger row = indexPath.row;

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if( !cell )
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    Contact *const c = [contacts objectAtIndex:row];
#if 0
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), c.recordID);
    ABMultiValueRef email = ABRecordCopyValue(person, kABPersonEmailProperty);
    CFIndex i = ABMultiValueGetIndexForIdentifier(email, c.emailID);
    CFTypeRef v = ABMultiValueCopyValueAtIndex(email, i);
    cell.text = [NSString stringWithFormat:@"%@ <%@>", ABRecordCopyCompositeName(person), v];
#else
    cell.textLabel.textAlignment = NSTextAlignmentCenter;

    CFErrorRef err;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &err);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
	if( granted )
	{
	    dispatch_async(dispatch_get_main_queue(), ^{
		cell.textLabel.text = (NSString*)CFBridgingRelease(ABRecordCopyCompositeName(ABAddressBookGetPersonWithRecordID(addressBook, c.recordID)));
	    });
	}
    });
#endif

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if( editingStyle == UITableViewCellEditingStyleDelete )
	{
		const NSInteger row = indexPath.row;
		[contacts removeObjectAtIndex:row];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:YES];
    }
    if( editingStyle == UITableViewCellEditingStyleInsert )
		[self showPeoplePicker];
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger row = indexPath.row;

	if( contacts && (row < [contacts count]) )
	{
		// Display the contact's details
		selectedContact = [contacts objectAtIndex:row];
		ABPersonViewController* pvc = [[ABPersonViewController alloc] init];
		pvc.allowsEditing = NO;

	    CFErrorRef err;
	    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &err);
	    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		if( granted )
		{
		    dispatch_async(dispatch_get_main_queue(), ^{
			pvc.displayedPerson = ABAddressBookGetPersonWithRecordID(addressBook, selectedContact.recordID);
		    });
		}
	    });

		pvc.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonEmailProperty]];
		pvc.personViewDelegate = self;
		[pvc setHighlightedItemForProperty:kABPersonEmailProperty withIdentifier:selectedContact.emailID];
		[self presentViewController:pvc animated:YES completion:nil];
	}
}

- (UITableViewCellEditingStyle) tableView:(UITableView*)tv editingStyleForRowAtIndexPath:(NSIndexPath*)path
{
    if( self.editing )
	return UITableViewCellEditingStyleDelete;
    return UITableViewCellEditingStyleNone;
}

#pragma mark -
#pragma mark <ABPeoplePickerNavigationControllerDelegate>

- (void) addPerson:(ABRecordRef)person identifier:(ABMultiValueIdentifier)identifier
{
    const ABRecordID recordID = ABRecordGetRecordID(person);

    if( !contacts )
	contacts = [[NSMutableArray alloc] init];
    else    // Nothing to do if the contact is already in the array
    {
	unsigned i = 0;
	for( Contact* c in contacts )
	{
	    if( (c.recordID == recordID) && (c.emailID == identifier) )
	    {
		// Scroll to and highlight the duplicate row so the user knows what's happening
		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
		return;
	    }
	    else
		++i;
	}
    }
    
    Contact *const c = [[Contact alloc] init];
    c.recordID = recordID;
    c.emailID = identifier;
    
	[contacts addObject:c];
	// insertRowsAtIndexPath calls cellForRowAtIndexPath before returning so
	//  contacts array must be changed first. Unfortunately, this means count
	//  can't be used here as an index.
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[contacts count]-1 inSection:0]] withRowAnimation:NO];
}

- (void) showPeoplePicker
{
	ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	picker.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonEmailProperty]];
	[self presentViewController:picker animated:YES completion:nil];
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)picker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	ABMultiValueRef email = ABRecordCopyValue(person, kABPersonEmailProperty);
	// If the record has only one email address, use it. Otherwise the user must choose.
	if( ABMultiValueGetCount(email) == 1 )
	{
		// Save the record id and property id
		[self addPerson:person identifier:ABMultiValueGetIdentifierAtIndex(email, 0)];
	CFRelease(email);
		[self dismissViewControllerAnimated:YES completion:nil];
		return NO;
	}
    CFRelease(email);
	return YES;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	[self addPerson:person identifier:identifier];
	[self dismissViewControllerAnimated:YES completion:nil];
	return NO;
}

#pragma mark -
#pragma mark <ABPersonViewControllerDelegate>

- (BOOL) personViewController:(ABPersonViewController*)pvc shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	selectedContact.emailID = identifier;
	[self dismissViewControllerAnimated:YES completion:nil];
	return NO;
}

@end

