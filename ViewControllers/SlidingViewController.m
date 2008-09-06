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

- (id)initWithStyle:(UITableViewStyle)style
{
	if( self = [super initWithStyle:style] )
	{
	}
	return self;
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
		editCellBottom = self.view.bounds.size.height - (cell.center.y + cell.bounds.size.height/2);
	return YES;
}

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

@end

