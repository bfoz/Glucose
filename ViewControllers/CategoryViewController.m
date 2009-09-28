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

static AppDelegate *appDelegate = nil;

@implementation CategoryViewController

@synthesize editedObject;

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = @"Categories";
		appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		dirty = NO;
		
		// Register to be notified whenever the insulinTypes array changes
		[appDelegate addObserver:self forKeyPath:@"categories" options:0 context:nil];
	}
	return self;
}

- (void)dealloc
{
    [editedObject release];
	[super dealloc];
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
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(appendNewCategory)];
	else
		self.navigationItem.rightBarButtonItem = nil;
	[tableView reloadData];
}

- (void) appendNewCategory
{
	[appDelegate addCategory:nil];	// Create a new Category record
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
	NSString *const cellID = self.editing ? @"EditCellID" : @"Cell";

	UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellID];
	if( !cell )
	{
		if( self.editing )
		{
			cell = [[[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
			((TextFieldCell*)cell).clearButtonMode = UITextFieldViewModeWhileEditing;
			cell.showsReorderControl = YES;
			((TextFieldCell*)cell).delegate = self;
			cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+3];
			((UITextField*)(((TextFieldCell*)cell).view)).returnKeyType = UIReturnKeyDone;
		}
		else
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	}

	// If not editing, the first row is "None", and the categories need to be shifted down one row.
	if( self.editing )
	{
		Category *const c = [appDelegate.categories objectAtIndex:indexPath.row];
		cell.textLabel.text = [c categoryName];
		((TextFieldCell*)cell).editedObject = c;
	}
	else
	{
		if( indexPath.row )
			cell.textLabel.text = [[appDelegate.categories objectAtIndex:(indexPath.row-1)] categoryName];
		else
			cell.textLabel.text = @"None";	// Dummy "none" category so the user can select no category			
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
	if( editedObject && ((![editedObject category] && !path.row) || (path.row && ([appDelegate.categories objectAtIndex:(path.row-1)] == [editedObject category]))) )
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

- (CGFloat) tableView:(UITableView*)tv heightForHeaderInSection:(NSInteger)section
{
	return self.editing ? 35 : 0;
}

- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
	if( self.editing )
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
	Category* c = cell.editedObject;
	if( !c || !cell )
		return;
	c.categoryName = (cell.text && cell.text.length) ? cell.text : nil;
	[appDelegate updateCategory:c];
}

@end

