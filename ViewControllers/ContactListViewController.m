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
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style])
	{
		self.title = @"Contact List";
    }
    return self;
}

- (void)dealloc
{
	[contacts release];
    [super dealloc];
}

- (void) setEditing:(BOOL)e animated:(BOOL)animated
{
	if( e )
		self.tableView.allowsSelectionDuringEditing = YES;
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
	if( contacts )
		return self.editing ? [contacts count]+1 : [contacts count];
    return self.editing ? 1 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
	const unsigned row = indexPath.row;

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if( !cell )
	{
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

	if( self.editing && ( !contacts || (row == [contacts count]) ) )
		cell.text = @"Add New Contact";
	else
	{
		Contact *const c = [contacts objectAtIndex:row];
		cell.text = (NSString*)ABRecordCopyCompositeName(ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), c.recordID));
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		const unsigned row = indexPath.row;
		[contacts removeObjectAtIndex:row];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:YES];
    }
    if (editingStyle == UITableViewCellEditingStyleInsert)
		[self showPeoplePicker];
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const unsigned row = indexPath.row;

	if( self.editing && ( !contacts || (row == [contacts count]) ) )
	{
		[self showPeoplePicker];
		return;
	}

	if( contacts && (row < [contacts count]) )
	{
		// Display the contact's details
		selectedContact = [contacts objectAtIndex:row];
		ABPersonViewController* pvc = [[ABPersonViewController alloc] init];
		pvc.allowsEditing = NO;
		pvc.displayedPerson = ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), selectedContact.recordID);
		pvc.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonEmailProperty]];
		pvc.personViewDelegate = self;
		[pvc setHighlightedItemForProperty:kABPersonEmailProperty withIdentifier:selectedContact.emailID];
		[self presentModalViewController:pvc animated:YES];
		[pvc release];
	}
}

- (UITableViewCellEditingStyle) tableView:(UITableView*)tv editingStyleForRowAtIndexPath:(NSIndexPath*)path
{
	if( self.editing && ( !contacts || (path.row == [contacts count]) ) )
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

#pragma mark -
#pragma mark <ABPeoplePickerNavigationControllerDelegate>

- (void) addPerson:(ABRecordRef)person identifier:(ABMultiValueIdentifier)identifier
{
	Contact *const c = [[Contact alloc] init];
	c.recordID = ABRecordGetRecordID(person);
	c.emailID = identifier;
	if( !contacts )
		contacts = [[NSMutableArray alloc] init];
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
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)picker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	NSString* name = (NSString*)ABRecordCopyCompositeName(person);
	NSLog(@"picked person %@", name);
	[name release];
	
	ABMultiValueRef email = ABRecordCopyValue(person, kABPersonEmailProperty);
	// If the record has only one email address, use it. Otherwise the user must choose.
	if( ABMultiValueGetCount(email) == 1 )
	{
		// Save the record id and property id
		[self addPerson:person identifier:ABMultiValueGetIdentifierAtIndex(email, 0)];
		[self dismissModalViewControllerAnimated:YES];
		return NO;
	}
	return YES;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	[self addPerson:person identifier:identifier];
	[self dismissModalViewControllerAnimated:YES];
	return NO;
}

#pragma mark -
#pragma mark <ABPersonViewControllerDelegate>

- (BOOL) personViewController:(ABPersonViewController*)pvc shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	selectedContact.emailID = identifier;
	[self dismissModalViewControllerAnimated:YES];
	return NO;
}

@end

