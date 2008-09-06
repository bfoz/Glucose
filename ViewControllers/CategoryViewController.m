//
//  CategoryViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Category.h"
#import "CategoryViewController.h"
#import "LogEntry.h"

@interface CategoryViewController ()

@property (nonatomic, readonly) AppDelegate *appDelegate;

- (void)saveAction:(id)sender;
- (void)setViewMovedUp:(BOOL)movedUp;

@end

@implementation CategoryViewController

@synthesize appDelegate, editedObject;

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = @"Category";
		appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		dirty = NO;
	}
	return self;
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
		[appDelegate flushCategories];
		dirty = NO;
		[appDelegate updateCategoryNameMaxWidth];
	}
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
	// In editing mode there is one extra row for "Add new category"
	// Otherwise there's an extra row for "None"
	// Either way, it's count+1
	return [appDelegate.categories count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	const BOOL notOnePastEnd = indexPath.row < [appDelegate.categories count];
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

	// If editing, the first row is the first category. If not editing, the first 
	//  row is "None", and the categories need to be shifted down one row.
	if( self.editing )
	{
		if( notOnePastEnd )
		{
			Category *const c = [appDelegate.categories objectAtIndex:indexPath.row];
			cell.text = [c categoryName];
			((TextFieldCell*)cell).editedObject = c;
		}
		else
			cell.text = @"Add New Category";
	}
	else
	{
		if( indexPath.row )
			cell.text = [[appDelegate.categories objectAtIndex:(indexPath.row-1)] categoryName];
		else
			cell.text = @"None";	// Dummy "none" category so the user can select no category			
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( editedObject && !self.editing )
	{
		// Row 0 is the "None" row
		Category* c = indexPath.row ? [appDelegate.categories objectAtIndex:indexPath.row-1] : nil;
		[editedObject setCategory:c];
	}

	// HI guidlines say row should be selected and then deselected
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if( self.parentViewController.modalViewController == self )
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

- (void) tableView:(UITableView*)tv willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)path
{
	// Put a checkmark on the currently selected row, or the None row if no category is set
	if( editedObject && ((![editedObject category] && !path.row) || ([appDelegate.categories objectAtIndex:(path.row-1)] == [editedObject category])) )
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
}

- (UITableViewCellEditingStyle) tableView:(UITableView*)tv editingStyleForRowAtIndexPath:(NSIndexPath*)path
{
	if( path.row >= [appDelegate.categories count] )
		return UITableViewCellEditingStyleInsert;
	else
		return UITableViewCellEditingStyleDelete;
}

- (BOOL) tableView:(UITableView*)tv canMoveRowAtIndexPath:(NSIndexPath*)path
{
	if( self.editing && (path.row < [appDelegate.categories count]) )
		return YES;
	return NO;
}

- (NSIndexPath*) tableView:(UITableView*)tv targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)fromPath toProposedIndexPath:(NSIndexPath*)toPath
{
	if( toPath.row < [appDelegate.categories count] )
		return toPath;
	return [NSIndexPath indexPathForRow:([appDelegate.categories count]-1) inSection:toPath.section];
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)path
{
    // If row is deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
	{
        unsigned categoryID = [[appDelegate.categories objectAtIndex:path.row] categoryID];
/*		// Get number of records for the category
		NSInteger numRecords = [appDelegate numRowsForCategoryID:categoryID];
		// Ask the user for confirmation if numRecords != 0
		if( numRecords )
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
															message:@"This will delete 1,000 record from the database"
														   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
			[alert show];
			[alert release];
			
		}
*/
		// Delete everything
		[appDelegate deleteEntriesForCategoryID:categoryID];
		[appDelegate deleteCategoryID:categoryID];
		[appDelegate.categories removeObjectAtIndex:path.row];

        // Animate the deletion from the table.
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    }
	if( editingStyle == UITableViewCellEditingStyleInsert )
	{
		// Append a new category record
		[appDelegate addCategory:nil];	// Create a new Category record
		[tv insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromPath toIndexPath:(NSIndexPath*)toPath
{
	NSLog(@"From Row %d to Row %d", fromPath.row, toPath.row);
	// Shuffle the categories array
	Category* c = [[appDelegate.categories objectAtIndex:fromPath.row] retain];
	[appDelegate.categories removeObjectAtIndex:fromPath.row];
	[appDelegate.categories insertObject:c atIndex:toPath.row];
	[c release];
	dirty = YES;
}
/*
#pragma mark -
#pragma mark <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSLog(@"Button index = %d", buttonIndex);
}
*/
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
	Category* c = cell.editedObject;
	if( !c || !cell )
		return;
	if( !c.categoryName && !cell.text )
		return;
	if( [c.categoryName isEqualToString:cell.text] )
		return;
	c.categoryName = (cell.text && cell.text.length) ? cell.text : nil;
	[appDelegate updateCategory:c];
}

- (void)saveAction:(id)sender
{
	[editCell resignFirstResponder];
	self.navigationItem.rightBarButtonItem = nil;
	editCell = nil;	//Not editing anything
}


@end

