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
#import "Constants.h"
#import "LogEntry.h"

@interface CategoryViewController ()

@property (nonatomic, readonly) AppDelegate *appDelegate;

@end

@implementation CategoryViewController

@synthesize appDelegate, editedObject;

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = @"Categories";
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

- (void) setEditing:(BOOL)e animated:(BOOL)animated
{
	[super setEditing:e animated:animated];
	// Flush the category array to the database if it has been modified
	if( dirty )
	{
		[appDelegate flushCategories];
		dirty = NO;
		[appDelegate updateCategoryNameMaxWidth];
	}
    // Eanble the Add button while editing
	if( e )
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(appendNewCategory)];
	else
		self.navigationItem.rightBarButtonItem = nil;
}

- (void) appendNewCategory
{
	NSIndexPath* path = [NSIndexPath indexPathForRow:[appDelegate.categories count] inSection:0];
	[appDelegate addCategory:nil];	// Create a new Category record
	[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self.tableView reloadData];	// Redisplay the data to update the checkmark
}

#pragma mark <UITableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// When not in editing mode there is one extra row for "None"
	return self.editing ? [appDelegate.categories count] : [appDelegate.categories count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString* cellID = self.editing ? @"EditCellID" : @"MyIdentifier";

	UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellID];
	if( !cell )
	{
		if( self.editing )
		{
			cell = [[[TextFieldCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
			((TextFieldCell*)cell).clearButtonMode = UITextFieldViewModeWhileEditing;
			cell.showsReorderControl = YES;
			((TextFieldCell*)cell).delegate = self;
			cell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+3];
		}
		else
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
	}

	// If not editing, the first row is "None", and the categories need to be shifted down one row.
	if( self.editing )
	{
		Category *const c = [appDelegate.categories objectAtIndex:indexPath.row];
		cell.text = [c categoryName];
		((TextFieldCell*)cell).editedObject = c;
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( editedObject && !self.editing )
	{
		// Row 0 is the "None" row
		Category* c = indexPath.row ? [appDelegate.categories objectAtIndex:indexPath.row-1] : nil;
		[editedObject setCategory:c];
	}

	// HI guidlines say row should be selected and then deselected
	[tv deselectRowAtIndexPath:indexPath animated:YES];

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

- (BOOL) tableView:(UITableView*)tv canMoveRowAtIndexPath:(NSIndexPath*)path
{
	return self.editing;
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
	return [self shouldBeginEditing:cell];
}

- (void)textFieldCellDidBeginEditing:(TextFieldCell*)cell
{
	[self didBeginEditing:cell field:cell.view action:@selector(saveAction)];
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

@end

