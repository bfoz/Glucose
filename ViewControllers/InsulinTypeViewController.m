//
//  InsulinTypeViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 8/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "InsulinType.h"
#import "InsulinTypeViewController.h"
#import "LogEntry.h"

@interface InsulinTypeViewController ()

@property (nonatomic, readonly) AppDelegate *appDelegate;

- (void)saveAction:(id)sender;
- (void)setViewMovedUp:(BOOL)movedUp;

@end

@implementation InsulinTypeViewController

@synthesize appDelegate, editedObject, editedIndex;

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = @"Insulin Type";
		appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		dirty = NO;
		numChecked = 0;
		multiCheck = NO;
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [editedObject release];
	[super dealloc];
}

- (void) setEditing:(BOOL)e
{
	[super setEditing:e];
	// Flush the category array to the database if it has been modified
	if( dirty )
	{
		[appDelegate flushInsulinTypes];
		dirty = NO;
		[appDelegate updateInsulinTypeShortNameMaxWidth];
	}
}

int sortDefaultInsulinTypes(id left, id right, void* insulinTypes)
{
	unsigned a = [((NSMutableArray*)insulinTypes) indexOfObjectIdenticalTo:left];
	unsigned b = [((NSMutableArray*)insulinTypes) indexOfObjectIdenticalTo:right];
	if( a < b )
		return NSOrderedAscending;
	if( a == b )
		return NSOrderedSame;
	return NSOrderedDescending;
}

- (void) setMultiCheck:(BOOL)e
{
	if( multiCheck && !e )	// If mutlicheck mode is ending
	{
		[appDelegate.defaultInsulinTypes sortUsingFunction:sortDefaultInsulinTypes context:appDelegate.insulinTypes];
		[appDelegate flushDefaultInsulinTypes];
	}
	multiCheck = e;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												 name:UIKeyboardWillShowNotification object:self.view.window]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) 
												 name:UIKeyboardWillHideNotification object:self.view.window]; 
    // Redisplay the data to update the checkmark
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil]; 
	// 
}

// Animate the entire view up or down, to prevent the keyboard from covering the edited field.
- (void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    // Make changes to the view's frame inside the animation block. They will be animated instead
    // of taking place immediately.
    CGRect rect = self.view.frame;
	
	CGFloat h = keyboardHeight - editFieldBottom;
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

#pragma mark Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notif
{
	CGRect r;
	[[notif.userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&r];
	keyboardHeight = r.size.height;
	if( editFieldBottom )
        [self setViewMovedUp:YES];
}

- (void)keyboardWillHide:(NSNotification*)notif
{
	if( editFieldBottom )
		[self setViewMovedUp:NO];
	editFieldBottom = 0;	// Clear this to indicate that nothing is being edited that needs the view moved
}

#pragma mark <UITableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// In editing mode there is one extra row for "Add new type"
	return self.editing ? [appDelegate.insulinTypes count] + 1 : [appDelegate.insulinTypes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	const BOOL notOnePastEnd = indexPath.row < [appDelegate.insulinTypes count];
	NSString* cellID = self.editing && notOnePastEnd ? @"EditCellID" : @"MyIdentifier";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	if( !cell )
	{
		if( self.editing && notOnePastEnd )
		{
			cell = [[[TextFieldCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
			((TextFieldCell*)cell).clearButtonMode = UITextFieldViewModeWhileEditing;
			cell.showsReorderControl = YES;
			((TextFieldCell*)cell).delegate = self;
			cell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+3];
		}
		else
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
		cell.textAlignment = UITextAlignmentCenter;
	}

	if( notOnePastEnd )
	{
		InsulinType *const type = [appDelegate.insulinTypes objectAtIndex:indexPath.row];
		cell.text = [type shortName];
		if( self.editing )
			((TextFieldCell*)cell).editedObject = type;
	}
	else
		cell.text = @"Add New Category";

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( editedObject  && !self.editing )
	{
		InsulinType* t = [appDelegate.insulinTypes objectAtIndex:indexPath.row];
		[self.editedObject setDoseType:t at:self.editedIndex];
	}

	// HI guidlines say row should be selected and then deselected
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if( multiCheck )
	{
		InsulinType *const type = [appDelegate.insulinTypes objectAtIndex:indexPath.row];
		UITableViewCell *const cell = [tableView cellForRowAtIndexPath:indexPath];
		if( [appDelegate.defaultInsulinTypes containsObject:type] )
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
			[appDelegate.defaultInsulinTypes removeObjectIdenticalTo:type];
		}
		else if( [appDelegate.defaultInsulinTypes count] < 2 )
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			[appDelegate.defaultInsulinTypes addObject:type];
		}
	}
	else if( self.parentViewController.modalViewController == self )
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

- (void) tableView:(UITableView*)tv willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)path
{
	// No accessory for out of range rows
	if( path.row >= [appDelegate.insulinTypes count] )
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
		return;
	}

	// Put a checkmark on the currently selected row
	InsulinType* t = [appDelegate.insulinTypes objectAtIndex:path.row];
	if( editedObject && (t == (InsulinType*)[[[editedObject insulin] objectAtIndex:self.editedIndex] type]) )
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else if( !editedObject && [appDelegate.defaultInsulinTypes containsObject:t] )
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
}

- (UITableViewCellEditingStyle) tableView:(UITableView*)tv editingStyleForRowAtIndexPath:(NSIndexPath*)path
{
	if( path.row >= [appDelegate.insulinTypes count] )
		return UITableViewCellEditingStyleInsert;
	else
		return UITableViewCellEditingStyleDelete;
}

- (BOOL) tableView:(UITableView*)tv canMoveRowAtIndexPath:(NSIndexPath*)path
{
	if( self.editing && (path.row < [appDelegate.insulinTypes count]) )
		return YES;
	return NO;
}

- (NSIndexPath*) tableView:(UITableView*)tv targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)fromPath toProposedIndexPath:(NSIndexPath*)toPath
{
	if( toPath.row < [appDelegate.insulinTypes count] )
		return toPath;
	return [NSIndexPath indexPathForRow:([appDelegate.insulinTypes count]-1) inSection:toPath.section];
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)path
{
    // If row is deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
	{
        unsigned typeID = [[appDelegate.insulinTypes objectAtIndex:path.row] typeID];

		// Delete everything
		[appDelegate deleteEntriesForInsulinTypeID:typeID];
		[appDelegate deleteInsulinTypeID:typeID];
		[appDelegate.insulinTypes removeObjectAtIndex:path.row];
		
        // Animate the deletion from the table.
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    }
	if( editingStyle == UITableViewCellEditingStyleInsert )
	{
		// Append a new category record
		[appDelegate addInsulinType:nil];	// Create a new Category record
		[tv insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromPath toIndexPath:(NSIndexPath*)toPath
{
	NSLog(@"From Row %d to Row %d", fromPath.row, toPath.row);
	// Shuffle the categories array
	InsulinType* type = [[appDelegate.insulinTypes objectAtIndex:fromPath.row] retain];
	[appDelegate.insulinTypes removeObjectAtIndex:fromPath.row];
	[appDelegate.insulinTypes insertObject:type atIndex:toPath.row];
	[type release];
	dirty = YES;
}

#pragma mark -
#pragma mark <TextFieldCellDelegate>

- (BOOL)textFieldCellShouldBeginEditing:(TextFieldCell*)cell
{
	if( !editFieldBottom )	// Ignore repeat calls
		editFieldBottom = self.view.bounds.size.height - (cell.center.y + cell.bounds.size.height/2);
	return YES;
}

- (void)textFieldCellDidBeginEditing:(TextFieldCell*)cell
{
	// Temporarily replace the navbar's Done button with one that dismisses the keyboard
	UIBarButtonItem* b = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																	   target:self
																	   action:@selector(saveAction:)];
	editCell = cell;
	self.navigationItem.rightBarButtonItem = b;
	[b release];
}

- (void)textFieldCellDidEndEditing:(TextFieldCell*)cell
{
	InsulinType* type = cell.editedObject;
	if( !type || !cell )
		return;
	if( !type.shortName && !cell.text )
		return;
	if( [type.shortName isEqualToString:cell.text] )
		return;
	type.shortName = (cell.text && cell.text.length) ? cell.text : nil;
	[appDelegate updateInsulinType:type];
}

- (void)saveAction:(id)sender
{
	[editCell resignFirstResponder];
	self.navigationItem.rightBarButtonItem = nil;
	editCell = nil;	//Not editing anything
}


@end
