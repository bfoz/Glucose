//
//  ContactListViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import	<AddressBookUI/AddressBookUI.h>

@class Contact;

@interface ContactListViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate>
{
	NSMutableArray*	contacts;
	Contact*		selectedContact;
}

@property (nonatomic, strong) NSMutableArray* contacts;

- (void) showPeoplePicker;

@end
