//
//  SlidingViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 9/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SlidingViewController.h"

@implementation SlidingViewController

@synthesize oldRightBarButtonItem;
@synthesize tableView;

// Interpose a generic UIView above the UITableView for holding the datePicker view
//  UITableView handles all non-tap touch events for its children, which
//	 prevents the UIDatePicker from seeing flicks. Making the datePicker a
//	 sibling of the UITableView allows it to get all events while visible.
- (void)loadView
{
	[super loadView];

	// Create a new UIView with the same size and position as the super's UITableView
	UIView *const v = [[UIView alloc] initWithFrame:[super.tableView frame]];
	// UITableViewController makes it difficult to set tableView and view independantly.
	//  Setting tableView sets view=tableView
	//  Setting view sets tableView=nil
	// So, use self.tableView to override super.tableView. But first, make a copy
	//  of super.tableView because it already points to a valid UITableView.
	UITableView *const tv = super.tableView;
	// Relocate the UITableView to the top of the UIView
	tv.frame = v.bounds;
	[v addSubview:tv];				// Reparent the UITableView
	self.tableView = tv;			// Keep a pointer to the UITableView created by the super
	self.view = v;					// Insert the new parent UIView
	[v release];
}

- (void)dealloc
{
	[datePicker release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    // Watch the keyboard so the user interface can be moved up or down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												 name:UIKeyboardWillShowNotification object:self.view.window]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) 
												 name:UIKeyboardWillHideNotification object:self.view.window]; 
}

- (void)viewDidDisappear:(BOOL)animated
{
    // Unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil]; 
}

#pragma mark -
#pragma mark Common Delegate Editing Handlers

- (BOOL)shouldBeginEditing:(UITableViewCell*)cell
{
	if( !editCellBottom )	// Ignore repeat calls
	{
		CGPoint bottom = CGPointMake(0, cell.frame.origin.y + cell.bounds.size.height);
		editCellBottom = [UIScreen mainScreen].bounds.size.height - [self.view convertPoint:bottom toView:nil].y;
	}
	return YES;
}

// The action selector is called when the Save button is tapped
- (void)didBeginEditing:(UITableViewCell*)cell field:(id)field action:(SEL)action
{
	// Temporarily replace the navbar's Done button with one that dismisses the keyboard
	UIBarButtonItem* b = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																	   target:self
																	   action:action];
	editCell = cell;
	editField = field;
	self.oldRightBarButtonItem = self.navigationItem.rightBarButtonItem;
	self.navigationItem.rightBarButtonItem = b;
	[b release];
}

- (void)saveAction
{
	self.navigationItem.rightBarButtonItem = oldRightBarButtonItem;
	oldRightBarButtonItem = nil;
	[editField resignFirstResponder];
	editCell = nil;	//Not editing anything
	editField = nil;
}

#pragma mark -
#pragma mark Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notif
{
	CGRect r;
	[[notif.userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&r];
	keyboardHeight = r.size.height;
	if( editCellBottom )
        [self setViewMovedUp:YES];
}

- (void)keyboardWillHide:(NSNotification*)notif
{
	if( editCellBottom )
		[self setViewMovedUp:NO];
	editCellBottom = 0;	// Clear this to indicate that nothing is being edited that needs the view moved
}

#pragma mark -
#pragma mark Sliding

// Animate the entire view up or down, to prevent the keyboard from covering the edited row
- (void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    // Make changes to the view's frame inside the animation block. They will be animated instead
    // of taking place immediately.
    CGRect rect = self.view.frame;

	CGFloat h = keyboardHeight - editCellBottom;
	h = (h<0) ? 0 : h;
	
    if (movedUp)
	{
        // If moving up, not only decrease the origin but increase the height so the view 
        // covers the entire screen behind the keyboard.
        rect.origin.y -= h;
        rect.size.height += h;
    }
	else
	{
        // If moving down, not only increase the origin but decrease the height.
        rect.origin.y += h;
        rect.size.height -= h;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark Date/Time Picker

- (void) didHideDatePicker:(NSString*)animationID finished:(BOOL)finished context:(void*)context
{
	((UIDatePicker*)context).hidden = YES;	// State change
}

- (void)hideDatePicker
{
	if( !datePicker || datePicker.hidden )
		return;
	
	[datePicker removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
	[self saveAction];
	
	[UIView beginAnimations:nil context:datePicker];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(didHideDatePicker:finished:context:)];
	[UIView setAnimationDuration:0.3];
	datePicker.frame = oldDatePickerRect;
	[UIView commitAnimations];
	
	[self setViewMovedUp:NO];	// Do this before clearing editCellBottom
	editCellBottom = 0;	// Clear this to indicate that nothing is being edited that needs the view moved
}

- (void) showDatePicker:(UITableViewCell*)cell mode:(UIDatePickerMode)mode initialDate:(NSDate*)date changeAction:(SEL)action
{
	if( !datePicker )
	{
		datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
		
		CGSize pickerSize = [datePicker sizeThatFits:CGSizeZero];
		CGRect rect = CGRectMake(0, self.view.bounds.size.height,
								 pickerSize.width, pickerSize.height);
		datePicker.frame = rect;
		
		// Setting hidden doesn't help with the animation so it's used as a state variable
		datePicker.hidden = YES;

		[self.view addSubview:datePicker];
	}
	
	datePicker.datePickerMode = mode;
	[datePicker addTarget:self action:action forControlEvents:UIControlEventValueChanged];

	// Nothing to do if already displaying the picker
	if( !datePicker.hidden )
		return;
	
	[self shouldBeginEditing:cell];	// Fake a delegate call
	
	[datePicker setDate:date animated:NO];
	datePicker.hidden = NO;	// State change
	CGRect rect = datePicker.frame;
	oldDatePickerRect = rect;
	keyboardHeight = [datePicker sizeThatFits:CGSizeZero].height;
	
	if( editCellBottom <= keyboardHeight )
		rect.origin.y = cell.frame.origin.y + cell.bounds.size.height;
	else
		rect.origin.y = oldDatePickerRect.origin.y - keyboardHeight;

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	datePicker.frame = rect;
	[UIView commitAnimations];
	
	// Pretend to be a keyboard
	[datePicker becomeFirstResponder];
	[self setViewMovedUp:YES];
	[self didBeginEditing:cell field:datePicker action:@selector(hideDatePicker)];
}

@end

