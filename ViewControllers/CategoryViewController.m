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
#import "LogModel.h"

#define	kCategoriesSectionNumber		0
#define	kRestoreDefaultsSectionNumber		1

@implementation CategoryViewController

@synthesize delegate;
@synthesize model;
@synthesize selectedCategory;

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = @"Categories";
	    didUndo = NO;
		dirty = NO;
	}
	return self;
}

- (void) setEditing:(BOOL)e animated:(BOOL)animated
{
	[super setEditing:e animated:animated];
	// Flush the category array to the database if it has been modified
	if( dirty )
		dirty = NO;

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

- (void)viewDidLoad
{
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self.tableView reloadData];	// Redisplay the data to update the checkmark
}

#pragma mark -

- (void) editRow
{
    NSIndexPath *const path = [NSIndexPath indexPathForRow:deleteRow inSection:0];
    TextFieldCell *const cell = (TextFieldCell*)[self.tableView cellForRowAtIndexPath:path];
    // Try again later if the row isn't visible yet
    if( cell )
	[cell.view becomeFirstResponder];
    else
	[self performSelector:@selector(editRow) withObject:nil afterDelay:0.1];
}

- (void) appendNewCategory
{
    if( [delegate respondsToSelector:@selector(categoryViewControllerCreateCategory)] )
    {
	const unsigned index = [model.categories count];
	[delegate categoryViewControllerCreateCategory];
	NSIndexPath *const path = [NSIndexPath indexPathForRow:index inSection:0];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:path]
			      withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionNone animated:YES];
	deleteRow = index;	// Reuse deleteRow to avoid creating a new variable
	[self performSelector:@selector(editRow) withObject:nil afterDelay:0.2];
    }
}

- (void) deleteCategory:(Category*)category atIndex:(unsigned)index
{
    [delegate categoryViewControllerDidDeleteCategory:category];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]]
			  withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark Shake handling

- (void)shaken
{
    // If editing a field, revert that field
    if( editCell )
    {
	didUndo = YES;	    // Flag that an undo operation is happening
	[((TextFieldCell*)editCell).textField resignFirstResponder];
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
	return self.editing ? [model.categories count] : [model.categories count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    const unsigned section = indexPath.section;
    NSString *const cellID = (self.editing && (section != kRestoreDefaultsSectionNumber)) ? @"EditCellID" : @"Cell";

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
		    Category *const c = [model.categories objectAtIndex:row];
		    ((TextFieldCell*)cell).editedObject = c;
		    ((TextFieldCell*)cell).textField.text = [c categoryName];
		    cell.accessibilityLabel = [c categoryName];
		}
		else
		{
		    if( row )	// A regular category row
		    {
			cell.textLabel.text = [[model.categories objectAtIndex:(row-1)] categoryName];
			// Set the row as selected if it matches the currently selected category
			if( [model.categories objectAtIndex:(row-1)] == selectedCategory )
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
	    if( [delegate respondsToSelector:@selector(categoryViewControllerDidSelectRestoreDefaults)] )
	    {
		[delegate categoryViewControllerDidSelectRestoreDefaults];
		[self.tableView reloadData];
	    }
    }
    else
    {
	const unsigned row = indexPath.row;
	// Row 0 is the "None" row
	selectedCategory = row ? [model.categories objectAtIndex:row-1] : nil;
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
	if( toPath.row < [model.categories count] )
		return toPath;
	return [NSIndexPath indexPathForRow:([model.categories count]-1) inSection:toPath.section];
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)path
{
    Category *const category = [model.categories objectAtIndex:path.row];

    // If row is deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
	// Get number of records for the category
	const unsigned numRecords = [appDelegate numRowsForCategoryID:category.categoryID];
	// Ask the user for confirmation if numRecords != 0
	if( numRecords )
	{
	    deleteCategory = category;
	    deleteRow = path.row;
	    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
							    message:[NSString stringWithFormat:@"Deleting category '%@' will move %u log entr%@ to category 'None'", category.categoryName, numRecords, ((numRecords>1)?@"ies":@"y")]
							   delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	    [alert show];
	    [alert release];		
	}
	else
	    [self deleteCategory:category atIndex:path.row];
    }
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromPath toIndexPath:(NSIndexPath*)toPath
{
    [model moveCategoryAtIndex:fromPath.row toIndex:toPath.row];
	dirty = YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( self.editing && (section != kRestoreDefaultsSectionNumber) )
	return @"Add, delete, rename or reorder categories";
    return nil;
}

#pragma mark -
#pragma mark <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex )
	[self deleteCategory:deleteCategory atIndex:deleteRow];
    else
	// Reload the table on cancel to work around a display bug
	[tableView reloadData];
}

#pragma mark -
#pragma mark <TextFieldCellDelegate>

- (void)textFieldCellDidBeginEditing:(TextFieldCell*)cell
{
    editCell = cell;
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
	[model updateCategory:c];
    }
    editCell = nil;	//Not editing anything
}

@end

