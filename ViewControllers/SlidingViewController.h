//
//  SlidingViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 9/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SlidingViewController : UITableViewController
{
	CGFloat			keyboardHeight;
	UITableViewCell*	editCell;
	id				editField;
	UIBarButtonItem*	oldRightBarButtonItem;

	UIDatePicker*	datePicker;
	CGRect			oldDatePickerRect;

	// UITableViewController::tableView is set whenever view is set, so create
	//  a new tableView property to mask the super's property
	UITableView*	tableView;
}

@property (nonatomic, retain)	UIBarButtonItem*	oldRightBarButtonItem;
@property (nonatomic, retain)	UITableView*		tableView;

- (void)setViewMovedUp:(BOOL)movedUp;

- (void)didBeginEditing:(UITableViewCell*)cell field:(id)field action:(SEL)action;
- (void) didEndEditing;
- (void)saveAction;

- (void)hideDatePicker;
- (void) showDatePicker:(UITableViewCell*)cell mode:(UIDatePickerMode)mode initialDate:(NSDate*)date changeAction:(SEL)action;
- (void) toggleDatePicker:(UITableViewCell*)cell mode:(UIDatePickerMode)mode initialDate:(NSDate*)date changeAction:(SEL)action;

@end
