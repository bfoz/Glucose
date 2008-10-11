//
//  InsulinTypeViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 8/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TextFieldCell.h"

#import "AppDelegate.h"
#import "InsulinType.h"
#import "InsulinTypeViewController.h"
#import "LogEntry.h"

@interface InsulinTypeViewController ()

@property (nonatomic, readonly) AppDelegate *appDelegate;

@end

@implementation InsulinTypeViewController

@synthesize appDelegate, editedObject, editedIndex;

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = @"Insulin Types";
		appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		dirty = NO;
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
	// In editing mode there is one extra row for "Add new type"
	return self.editing ? [appDelegate.insulinTypes count] + 1 : [appDelegate.insulinTypes count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	const BOOL notOnePastEnd = indexPath.row < [appDelegate.insulinTypes count];
	NSString* cellID = self.editing && notOnePastEnd ? @"EditCellID" : @"MyIdentifier";

	UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellID];
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( editedObject  && !self.editing )
	{
		InsulinType* t = [appDelegate.insulinTypes objectAtIndex:indexPath.row];
		[self.editedObject setDoseType:t at:self.editedIndex];
	}

	// HI guidlines say row should be selected and then deselected
	[tv deselectRowAtIndexPath:indexPath animated:YES];

	if( multiCheck )
	{
		InsulinType *const type = [appDelegate.insulinTypes objectAtIndex:indexPath.row];
		UITableViewCell *const cell = [tv cellForRowAtIndexPath:indexPath];
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
	return [self shouldBeginEditing:cell];
}

- (void)textFieldCellDidBeginEditing:(TextFieldCell*)cell
{
	[self didBeginEditing:cell field:cell.view action:@selector(saveAction)];
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

@end
