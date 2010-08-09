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

#define	kCategoriesSectionNumber		0
#define	kRestoreDefaultsSectionNumber		1

@implementation CategoryViewController

@synthesize delegate;
@synthesize selectedCategory;

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = @"Categories";
	    didUndo = NO;
		dirty = NO;
		
		// Register to be notified whenever the insulinTypes array changes
		[appDelegate addObserver:self forKeyPath:@"categories" options:0 context:nil];
	}
	return self;
}

// Handle change notifications for observed key paths of other objects.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqual:@"categories"] )
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
		[appDelegate flushCategories];
		dirty = NO;
		[appDelegate updateCategoryNameMaxWidth];
	}
    // Eanble the Add button while editing
	if( e )
	{
	    [[NSNotificationCenter defaultCenter] addObserver:self
						     selector:@selector(shaken)
							 name:@"shaken"
						       object:nil];

		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(appendNewCategory)];
	}
	else
	{
	    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"shaken" object:nil];

		self.navigationItem.rightBarButtonItem = nil;
	}
	[tableView reloadData];
}

- (void) appendNewCategory
{
	[appDelegate addCategory:nil];	// Create a new Category record
}

- (void)viewDidLoad
{
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self.tableView reloadData];	// Redisplay the data to update the checkmark
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

	// When not in editing mode there is one extra row for "None"
	return self.editing ? [appDelegate.categories count] : [appDelegate.categories count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *const cellID = self.editing ? @"EditCellID" : @"Cell";
    const unsigned section = indexPath.section;

	UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellID];
	if( !cell )
	{
		if( self.editing )
		{
	    switch( section )
	    {
		case kCategoriesSectionNumber:
			cell = [[[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		    ((TextFieldCell*)cell).textField.clearButtonMode = UITextFieldViewModeWhileEditing;
			cell.showsReorderControl = YES;
			((TextFieldCell*)cell).delegate = self;
		    ((TextFieldCell*)cell).textField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+3];
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

	// If not editing, the first row is "None", and the categories need to be shifted down one row.
	switch( section )
	{
	    case kCategoriesSectionNumber:
	    {
		const unsigned row = indexPath.row;

		if( self.editing )
		{
		    Category *const c = [appDelegate.categories objectAtIndex:row];
		    ((TextFieldCell*)cell).editedObject = c;
		    ((TextFieldCell*)cell).textField.text = [c categoryName];
		}
		else
		{
		    if( row )	// A regular category row
		    {
			cell.textLabel.text = [[appDelegate.categories objectAtIndex:(row-1)] categoryName];
			// Set the row as selected if it matches the currently selected category
			if( [appDelegate.categories objectAtIndex:(row-1)] == selectedCategory )
			    [tv selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		    }
		    else	// The "None" row
		    {
			cell.textLabel.text = @"None";	// Dummy "none" category so the user can select no category
			// Set the "None" row as selected if no category is currently selected
			if( !selectedCategory )
			    [tv selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		    }
		}

		break;
	    }
	    case kRestoreDefaultsSectionNumber:
		cell.textLabel.text = @"Restore Default Categories";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		break;
	}

	return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( self.editing )
    {
	if( kRestoreDefaultsSectionNumber == indexPath.section )
	    [appDelegate appendBundledCategories];    // Restore the missing defaults
    }
    else
    {
	const unsigned row = indexPath.row;
	// Row 0 is the "None" row
	selectedCategory = row ? [appDelegate.categories objectAtIndex:row-1] : nil;
	if( [delegate respondsToSelector:@selector(categoryViewControllerDidSelectCategory:)] )
	    [delegate categoryViewControllerDidSelectCategory:selectedCategory];

	if( self.parentViewController.modalViewController == self )
	    [self.parentViewController dismissModalViewControllerAnimated:YES];
	else
	    [self.navigationController popViewControllerAnimated:YES];
    }

    // HI guidlines say row should be selected and then deselected
    [tv deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)path
{
    return kRestoreDefaultsSectionNumber != path.section;
}

- (BOOL) tableView:(UITableView*)tv canMoveRowAtIndexPath:(NSIndexPath*)path
{
	return self.editing && (path.section != kRestoreDefaultsSectionNumber);
}

- (NSIndexPath*) tableView:(UITableView*)tv targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)fromPath toProposedIndexPath:(NSIndexPath*)toPath
{
	if( toPath.row < [appDelegate.categories count] )
		return toPath;
	return [NSIndexPath indexPathForRow:([appDelegate.categories count]-1) inSection:toPath.section];
}

- (CGFloat) tableView:(UITableView*)tv heightForHeaderInSection:(NSInteger)section
{
	return self.editing ? 35 : 0;
}

- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
	if( self.editing && (section != kRestoreDefaultsSectionNumber) )
	{
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.numberOfLines = 2;
		label.text = @"Add, delete, rename or reorder categories";
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
    // If row is deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
	Category *const category = [appDelegate.categories objectAtIndex:path.row];
	// Get number of records for the category
	const unsigned numRecords = [appDelegate numRowsForCategoryID:category.categoryID];
	// Ask the user for confirmation if numRecords != 0
	if( numRecords )
	{
	    deleteRowNum = path.row;
	    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
							    message:[NSString stringWithFormat:@"Deleting category %@ will delete %u log entr%@", category.categoryName, numRecords, ((numRecords>1)?@"ies":@"y")]
							   delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	    [alert show];
	    [alert release];		
	}
	else
	    // Purge the record from the database and the categories array
	    [appDelegate purgeCategoryAtIndex:path.row];
    }
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromPath toIndexPath:(NSIndexPath*)toPath
{
//	NSLog(@"From Row %d to Row %d", fromPath.row, toPath.row);
	// Shuffle the categories array
	Category* c = [[appDelegate.categories objectAtIndex:fromPath.row] retain];
	[appDelegate.categories removeObjectAtIndex:fromPath.row];
	[appDelegate.categories insertObject:c atIndex:toPath.row];
	[c release];
	dirty = YES;
}

#pragma mark -
#pragma mark <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex )
    {
	// Purge the record from the database and the categories array
	[appDelegate purgeCategoryAtIndex:deleteRowNum];
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
	Category* c = cell.editedObject;
	if( !c || !cell )
		return;
	c.categoryName = (cell.text && cell.text.length) ? cell.text : nil;
	[appDelegate updateCategory:c];
    }
}

@end

