#import "CategoryViewController.h"
#import "Constants.h"
#import "FlurryLogger.h"

#import "LogEntry.h"
#import "LogModel+CoreData.h"
#import "ManagedCategory.h"

#define	kCategoriesSectionNumber		0
#define	kRestoreDefaultsSectionNumber		1

@interface CategoryViewController () <NSFetchedResultsControllerDelegate>
@end

@implementation CategoryViewController
{
    BOOL    userDrivenChange;
    ManagedCategory*	deleteCategory;
    NSFetchedResultsController*	fetchedResultsController;
}

@synthesize model;

- (id) initWithStyle:(UITableViewStyle)style logModel:(LogModel*)logModel
{
    self = [super initWithStyle:style];
    if( self )
    {
	self.title = @"Categories";
	userDrivenChange = NO;

	model = logModel;

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[LogModel fetchRequestForOrderedCategories]
								       managedObjectContext:model.managedObjectContext
									 sectionNameKeyPath:nil
										  cacheName:nil];
	fetchedResultsController.delegate = self;

	NSError* error = nil;
	[fetchedResultsController performFetch:&error];
	if( error )
	    [FlurryLogger logError:@"Unresolved Error" message:[error localizedDescription] error:error];

    }
    return self;
}

- (void) setEditing:(BOOL)e animated:(BOOL)animated
{
	[super setEditing:e animated:animated];

    // Eanble the Add button while editing
	if( e )
	    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(appendNewCategory)];
	else
	    self.navigationItem.rightBarButtonItem = nil;
	[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsSelectionDuringEditing = YES;
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
    const unsigned index = fetchedResultsController.fetchedObjects.count;

    [model addCategoryWithName:nil];
    [model save];

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:kCategoriesSectionNumber]
			  atScrollPosition:UITableViewScrollPositionNone
				  animated:YES];
    deleteRow = index;	// Reuse deleteRow to avoid creating a new variable
    [self performSelector:@selector(editRow) withObject:nil afterDelay:0.2];
}

- (void) configureCell:(UITableViewCell*)cell forCategory:(ManagedCategory*)category
{
    if( self.editing )
    {
	((TextFieldCell*)cell).editedObject = category;
	((TextFieldCell*)cell).textField.text = [category name];
	cell.accessibilityLabel = [category name];
    }
    else
    {
	cell.textLabel.text = [category name];
	// Set the row as selected if it matches the currently selected category
	if( [category isEqual:self.selectedCategory] )
	    [self.tableView selectRowAtIndexPath:[self.tableView indexPathForCell:cell]
					animated:NO
				  scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void) deleteCategory:(ManagedCategory*)category
{
    [model removeCategory:category];
    [model save];
}

- (NSIndexPath*) translateFetchedIndexPath:(NSIndexPath*)indexPath
{
    return self.editing ? indexPath : [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
}

- (NSIndexPath*) translateTableViewIndexPath:(NSIndexPath*)indexPath
{
    return self.editing ? indexPath : [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
}

#pragma mark - Delegates

#pragma mark NSFetchedResultsControllerDelegate

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if( !userDrivenChange )
	[self.tableView beginUpdates];
}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch( type )
    {
	case NSFetchedResultsChangeDelete:
	    [self.tableView deleteRowsAtIndexPaths:@[[self translateFetchedIndexPath:indexPath]]
				  withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeInsert:
	    [self.tableView insertRowsAtIndexPaths:@[[self translateFetchedIndexPath:newIndexPath]]
				  withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeMove:
	    if( !userDrivenChange )
	    {
		[self.tableView deleteRowsAtIndexPaths:@[[self translateFetchedIndexPath:indexPath]]
				      withRowAnimation:UITableViewRowAnimationAutomatic];
		[self.tableView insertRowsAtIndexPaths:@[[self translateFetchedIndexPath:newIndexPath]]
				      withRowAnimation:UITableViewRowAnimationAutomatic];
	    }
	    break;
	case NSFetchedResultsChangeUpdate:
	    if( !userDrivenChange )
	    {
		[self configureCell:[self.tableView cellForRowAtIndexPath:[self translateFetchedIndexPath:indexPath]]
			forCategory:[fetchedResultsController objectAtIndexPath:indexPath]];
	    }
	    break;
    }
}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
    switch( type )
    {
	case NSFetchedResultsChangeDelete:
	    [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeInsert:
	    [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
    }
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if( !userDrivenChange )
	[self.tableView endUpdates];
}

#pragma mark <UITableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSUInteger count = fetchedResultsController.sections.count;

    // Edit mode shows an extra section for restoring defaults
    if( self.editing )
	++count;

    return count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( kRestoreDefaultsSectionNumber == section )
	return 1;

    NSArray* sections = fetchedResultsController.sections;
    if( 0 == sections.count )
	return 0;

    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    NSUInteger count = [sectionInfo numberOfObjects];

    // When not in editing mode there is one extra row for "None"
    if( !self.editing )
	++count;

    return count;
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
			cell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		    ((TextFieldCell*)cell).textField.clearButtonMode = UITextFieldViewModeWhileEditing;
			cell.showsReorderControl = YES;
			((TextFieldCell*)cell).delegate = self;
		    ((TextFieldCell*)cell).textField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+3];
		    ((TextFieldCell*)cell).textField.returnKeyType = UIReturnKeyDone;
		    break;
		case kRestoreDefaultsSectionNumber:
		    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		    break;
	    }
		}
		else
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	}

    // If not editing, the first row is "None", and the categories need to be shifted down one row.
    switch( section )
    {
	case kCategoriesSectionNumber:
	{
	    if( self.editing )
		[self configureCell:cell forCategory:[fetchedResultsController objectAtIndexPath:indexPath]];
	    else
	    {
		if( 0 != indexPath.row )	// A regular category row
		    [self configureCell:cell
			    forCategory:[fetchedResultsController objectAtIndexPath:[self translateTableViewIndexPath:indexPath]]];
		else
		{
		    cell.textLabel.text = @"None";	// Dummy "none" category so the user can select no category
		    // Set the "None" row as selected if no category is currently selected
		    if( !self.selectedCategory )
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
	    if( [self.delegate respondsToSelector:@selector(categoryViewControllerDidSelectRestoreDefaults)] )
		[self.delegate categoryViewControllerDidSelectRestoreDefaults];
    }
    else
    {
	const unsigned row = indexPath.row;
	// Row 0 is the "None" row
	self.selectedCategory = row ? [fetchedResultsController objectAtIndexPath:[self translateTableViewIndexPath:indexPath]] : nil;
	if( [self.delegate respondsToSelector:@selector(categoryViewControllerDidSelectCategory:)] )
	    [self.delegate categoryViewControllerDidSelectCategory:self.selectedCategory];
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
    if( (toPath.section == kCategoriesSectionNumber) && ([self translateTableViewIndexPath:toPath].row < fetchedResultsController.fetchedObjects.count) )
	    return toPath;
    return [self translateFetchedIndexPath:[NSIndexPath indexPathForRow:(fetchedResultsController.fetchedObjects.count-1) inSection:kCategoriesSectionNumber]];
}

#pragma mark - <UITableViewDataSource>

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)path
{
    ManagedCategory* category = [fetchedResultsController objectAtIndexPath:[self translateTableViewIndexPath:path]];

    // If row is deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
	const unsigned numRecords = category.logEntries.count;
	// Ask the user for confirmation if numRecords != 0
	if( numRecords )
	{
	    deleteCategory = category;
	    deleteRow = path.row;
	    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
							    message:[NSString stringWithFormat:@"Deleting category '%@' will move %u log entr%@ to category 'None'", category.name, numRecords, ((numRecords>1)?@"ies":@"y")]
							   delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	    [alert show];
	}
	else
	    [self deleteCategory:category];
    }
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
    userDrivenChange = YES;

    NSMutableArray* categories = [[fetchedResultsController fetchedObjects] mutableCopy];
    NSManagedObject* category = [fetchedResultsController objectAtIndexPath:fromIndexPath];

    [categories removeObject:category];
    [categories insertObject:category atIndex:toIndexPath.row];

    unsigned index = 0;
    for( ManagedCategory* category in categories )
	category.sequenceNumber = [NSNumber numberWithInt:index++];

    [model save];

    userDrivenChange = NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( self.editing && (section != kRestoreDefaultsSectionNumber) )
	return @"Add, delete, rename or reorder categories";
    return nil;
}

#pragma mark - <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex )
	[self deleteCategory:deleteCategory];
    else
	// Reload the table on cancel to work around a display bug
	[self.tableView reloadData];
}

#pragma mark - <TextFieldCellDelegate>

- (void)textFieldCellDidEndEditing:(TextFieldCell*)cell
{
    ManagedCategory* c = cell.editedObject;
    if( !c || !cell )
	return;
    c.name = (cell.text && cell.text.length) ? cell.text : nil;
    [model save];
}

@end

