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
	CGFloat			editCellBottom;
	CGFloat			keyboardHeight;
	UITableViewCell*	editCell;
	id				editField;
	UIBarButtonItem*	oldRightBarButtonItem;

	UIDatePicker*	datePicker;
	CGRect			oldDatePickerRect;
}

@property (nonatomic, retain)	UIBarButtonItem*	oldRightBarButtonItem;

- (void)setViewMovedUp:(BOOL)movedUp;

- (void)didBeginEditing:(UITableViewCell*)cell field:(id)field action:(SEL)action;
- (void)saveAction;
- (BOOL)shouldBeginEditing:(UITableViewCell*)cell;

- (void)hideDatePicker;
- (void) showDatePicker:(UITableViewCell*)cell mode:(UIDatePickerMode)mode initialDate:(NSDate*)date changeAction:(SEL)action;

@end
