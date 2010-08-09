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

#define	kInsulinTypesSectionNumber		0
#define	kRestoreDefaultsSectionNumber		1

@implementation InsulinTypeViewController

@synthesize delegate;
@synthesize multiCheck;
@synthesize selectedInsulinTypes;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style])
    {
	self.title = @"Insulin Types";
	didUndo = NO;
	dirty = NO;
	multiCheck = NO;

	// Register to be notified whenever the insulinTypes array changes
	[appDelegate addObserver:self forKeyPath:@"insulinTypes" options:0 context:nil];
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [selectedInsulinTypes release];
	[super dealloc];
}

// Handle change notifications for observed key paths of other objects.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqual:@"insulinTypes"] )
    {
	const int kind = [[change valueForKey:NSKeyValueChangeKindKey] intValue];
	const unsigned row = [[change valueForKey:NSKeyValueChangeIndexesKey] firstIndex];
	switch( kind )
	{
	    case NSKeyValueChangeSetting:
		[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]] setNeedsDisplay];
		break;
	    case NSKeyValueChangeInsertion:
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		break;
	    case NSKeyValueChangeRemoval:
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		break;
	}
    }
    // Verify that the superclass does indeed handle these notifications before actually invoking that method.
    else if( [[self superclass] instancesRespondToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)] )
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) setEditing:(BOOL)e animated:(BOOL)animated
{
    [super setEditing:e animated:animated];
    // Flush the category array to the database if it has been modified
    if( dirty )
    {
	[appDelegate flushInsulinTypes];
	dirty = NO;
	[appDelegate updateInsulinTypeShortNameMaxWidth];
    }
    // Eanble the Add button while editing
    if( e )
    {
	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(shaken)
						     name:@"shaken"
						   object:nil];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(appendNewInsulinType)];
    }
    else
    {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"shaken" object:nil];

	self.navigationItem.rightBarButtonItem = nil;
    }
    [tableView reloadData];
}

- (void) appendNewInsulinType
{
    [appDelegate addInsulinType:nil];	// Create a new Category record
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

#pragma mark Shake handling

- (void)shaken
{
    // If editing a field, revert that field
    if( editCell )
    {
	didUndo = YES;	    // Flag that an undo operation is happening
	[self saveAction];  // Cancel the edit
	[self.tableView reloadData];
    }
}

#pragma mark -
#pragma mark External Interface

- (void) setSelectedInsulinType:(InsulinType*)type
{
    if( selectedInsulinTypes )
    {
	[selectedInsulinTypes removeAllObjects];
	[selectedInsulinTypes addObject:type];
    }
    else
	selectedInsulinTypes = [[NSMutableSet setWithObject:type] retain];
}

- (void) setSelectedInsulinTypes:(NSArray*)types
{
    if( selectedInsulinTypes )
    {
	[selectedInsulinTypes removeAllObjects];
	[selectedInsulinTypes addObjectsFromArray:types];
    }
    else
	selectedInsulinTypes = [[NSMutableSet setWithArray:types] retain];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.allowsSelectionDuringEditing = YES;
    [self.tableView reloadData];	// Redisplay the data to update the checkmark
}

- (void) viewWillDisappear:(BOOL)animated
{
    if( multiCheck )
    {
	[appDelegate.defaultInsulinTypes sortUsingFunction:sortDefaultInsulinTypes context:appDelegate.insulinTypes];
	[appDelegate flushDefaultInsulinTypes];
    }
    [super viewWillDisappear:animated];
}

- (void) purgeInsulinTypeAtIndex:(unsigned)index
{
    InsulinType *const type = [appDelegate.insulinTypes objectAtIndex:index];
    const unsigned numRecords = [appDelegate numLogEntriesForInsulinTypeID:type.typeID];
    // Ask the user for confirmation if numRecords != 0
    if( numRecords )
    {
	alertReason = ALERT_REASON_TYPE_NOT_EMPTY;
	deleteRowNum = index;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
							message:[NSString stringWithFormat:@"Deleting Insulin %@ will delete dose information from %u log entr%@", type.shortName, numRecords, ((numRecords>1)?@"ies":@"y")]
						       delegate:self
					      cancelButtonTitle:@"Cancel"
					      otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
    }
    else
	// Purge the record from the database and the insulinTypes array
	[appDelegate purgeInsulinTypeAtIndex:index];
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Edit mode shows an extra section for restoring defaults
    return self.editing ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( kRestoreDefaultsSectionNumber == section )
	return 1;

    return [appDelegate.insulinTypes count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
    const unsigned section = indexPath.section;
    NSString* cellID = self.editing && (section != kRestoreDefaultsSectionNumber) ? @"EditCellID" : @"Cell";

    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellID];
    if( !cell )
    {
	if( self.editing )
	{
	    switch( section )
	    {
		case kInsulinTypesSectionNumber:
		    cell = [[[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		    ((TextFieldCell*)cell).clearButtonMode = UITextFieldViewModeWhileEditing;
		    cell.showsReorderControl = YES;
		    ((TextFieldCell*)cell).delegate = self;
		    ((TextFieldCell*)cell).font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+3];
		    ((TextFieldCell*)cell).textField.returnKeyType = UIReturnKeyDone;
		    break;
		case kRestoreDefaultsSectionNumber:
		    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		    break;
	    }
	}
	else
	    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
    }

    switch( section )
    {
	case kInsulinTypesSectionNumber:
	{
	    // Get the row's insulin type object
	    InsulinType *const type = [appDelegate.insulinTypes objectAtIndex:indexPath.row];

	    // Put a checkmark on the currently selected row(s)
	    if( [selectedInsulinTypes containsObject:type] )
	    {
		if( multiCheck )
		    cell.accessoryType = UITableViewCellAccessoryCheckmark;
		else
		    [tv selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	    }
	    else
		cell.accessoryType = UITableViewCellAccessoryNone;

	    if( self.editing )
	    {
		((TextFieldCell*)cell).editedObject = type;
		((TextFieldCell*)cell).textField.text = [type shortName];

		// Highlight the row if its insulin type is on the list of types used for new entries
		if( NSNotFound != [appDelegate.defaultInsulinTypes indexOfObjectIdenticalTo:type] )
		    ((TextFieldCell*)cell).textField.textColor = [UIColor blueColor];
		else
		    ((TextFieldCell*)cell).textField.textColor = [UIColor blackColor];
	    }
	    else
	    {
		cell.textLabel.text = [type shortName];
		cell.textLabel.textColor = [UIColor blackColor];
	    }
	    break;
	}
	case kRestoreDefaultsSectionNumber:
	    cell.textLabel.text = @"Restore Default Types";
	    cell.textLabel.textAlignment = UITextAlignmentCenter;
	    break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // HI guidlines say row should be selected and then deselected
    [tv deselectRowAtIndexPath:indexPath animated:YES];

    // The Restore Defaults button is only displayed in edit mode
    if( kRestoreDefaultsSectionNumber == indexPath.section )
	[appDelegate appendBundledInsulinTypes];	// Restore the missing defaults
    else
    {
	UITableViewCell *const cell = [tv cellForRowAtIndexPath:indexPath];
	InsulinType *const t = [appDelegate.insulinTypes objectAtIndex:indexPath.row];

	// Toggle the checkmark on the selected row and notify the delegate
	//  The delegate can block the selection event by returning NO
	if( UITableViewCellAccessoryNone == cell.accessoryType )
	{
	    if( [delegate respondsToSelector:@selector(insulinTypeViewControllerDidSelectInsulinType:)] )
		if( [delegate insulinTypeViewControllerDidSelectInsulinType:t] )
		{
		    if( multiCheck )
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		    else
			[selectedInsulinTypes removeAllObjects];
		    [selectedInsulinTypes addObject:t];
		}
	}
	else
	{
	    cell.accessoryType = UITableViewCellAccessoryNone;
	    [selectedInsulinTypes removeObject:t];
	    if( [delegate respondsToSelector:@selector(insulinTypeViewControllerDidUnselectInsulinType:)] )
		[delegate insulinTypeViewControllerDidUnselectInsulinType:t];
	}

	// Don't need to pop/dismiss when in multicheck mode (the nav controller handles it)
	if( !multiCheck )
	{
	    if( self.parentViewController.modalViewController == self )
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	    else
		[self.navigationController popViewControllerAnimated:YES];
	}
    }
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)path
{
    return kRestoreDefaultsSectionNumber != path.section;
}

- (BOOL) tableView:(UITableView*)tv canMoveRowAtIndexPath:(NSIndexPath*)path
{
    return self.editing && (path.section != kRestoreDefaultsSectionNumber);
}

- (NSIndexPath*) tableView:(UITableView*)tv targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)fromPath toProposedIndexPath:(NSIndexPath*)toPath
{
    if( toPath.row < [appDelegate.insulinTypes count] )
	return toPath;
    return [NSIndexPath indexPathForRow:([appDelegate.insulinTypes count]-1) inSection:toPath.section];
}

- (CGFloat) tableView:(UITableView*)tv heightForHeaderInSection:(NSInteger)section
{
    return (multiCheck || self.editing) ? 35 : 0;
}

- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    if( multiCheck )
    {
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.numberOfLines = 2;
	label.text = @"Choose up to 2 insulin types to be automatically added to new log entries";
	label.textAlignment = UITextAlignmentCenter;
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];;
	return label;
    }
    else if( self.editing  && (section != kRestoreDefaultsSectionNumber) )
    {
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.numberOfLines = 2;
	label.text = @"Add, delete, rename or reorder insulin types";
	label.textAlignment = UITextAlignmentCenter;
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];;
	return label;
    }
    return nil;
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)path
{
    // If a row is deleted, remove it from the list
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
	// If the row corresponds to a type that's used as a default insulin
	//  type for new log entries, then ask the user for confirmation first
	InsulinType *const type = [appDelegate.insulinTypes objectAtIndex:path.row];
	if( NSNotFound != [appDelegate.defaultInsulinTypes indexOfObjectIdenticalTo:type] )
	{
	    alertReason = ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE;
	    deleteRowNum = path.row;
	    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
							    message:[NSString stringWithFormat:@"Insulin %@ is used for new log entries. If you delete this insulin type it will no longer be displayed for new log entries.", type.shortName]
							   delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	    [alert show];
	    [alert release];
	}
	else	// Otherwise, carry on
	    [self purgeInsulinTypeAtIndex:path.row];
    }
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromPath toIndexPath:(NSIndexPath*)toPath
{
    NSLog(@"From Row %d to Row %d", fromPath.row, toPath.row);
    // Shuffle the insulinTypes array
    InsulinType* type = [[appDelegate.insulinTypes objectAtIndex:fromPath.row] retain];
    [appDelegate.insulinTypes removeObjectAtIndex:fromPath.row];
    [appDelegate.insulinTypes insertObject:type atIndex:toPath.row];
    [type release];
    dirty = YES;
}

#pragma mark -
#pragma mark <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex )
    {
	switch( alertReason )
	{
	    case ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE:
		[self purgeInsulinTypeAtIndex:deleteRowNum];
		break;
	    case ALERT_REASON_TYPE_NOT_EMPTY:
		// Purge the record from the database and the Insulin Types array
		[appDelegate purgeInsulinTypeAtIndex:deleteRowNum];
		break;
	}
    }
    else
	// Reload the table on cancel to work around a display bug
	[tableView reloadData];
}

#pragma mark -
#pragma mark <TextFieldCellDelegate>

- (void)textFieldCellDidBeginEditing:(TextFieldCell*)cell
{
    [self didBeginEditing:cell field:cell.view action:@selector(saveAction)];
}

- (void)textFieldCellDidEndEditing:(TextFieldCell*)cell
{
    if( didUndo )
	didUndo = NO;	// Undo handled
    else
    {
	InsulinType* type = cell.editedObject;
	if( !type || !cell )
	    return;
	type.shortName = (cell.text && cell.text.length) ? cell.text : nil;
	[appDelegate updateInsulinType:type];
    }
}

@end
