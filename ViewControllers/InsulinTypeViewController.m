#import "InsulinTypeViewController.h"
#import "FlurryLogger.h"

#import "LogModel+CoreData.h"
#import "ManagedInsulinType.h"
#import "TextFieldCell.h"

#define	kInsulinTypesSectionNumber		0
#define	kRestoreDefaultsSectionNumber		1

@interface InsulinTypeViewController () <NSFetchedResultsControllerDelegate>
@end

@implementation InsulinTypeViewController
{
    ManagedInsulinType*	deleteInsulinType;
    NSUInteger		deleteRowNum;
    BOOL    userDrivenChange;
    NSMutableSet*	selectedInsulinTypes;
    NSFetchedResultsController*	fetchedResultsController;
}

@synthesize model;
@synthesize multiCheck;

- (id) initWithStyle:(UITableViewStyle*)style logModel:(LogModel*)logModel
{
    if( self = [super initWithStyle:style] )
    {
	self.title = @"Insulin Types";
	multiCheck = NO;

	model = logModel;

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[LogModel fetchRequestForOrderedInsulinTypes]
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
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(appendNewInsulinType)];
    else
	self.navigationItem.rightBarButtonItem = nil;
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark External Interface

- (BOOL) insulinTypeIsSelected:(ManagedInsulinType*)insulinType
{
    return [selectedInsulinTypes containsObject:insulinType];
}

- (void) setSelectedInsulinType:(ManagedInsulinType*)type
{
    if( selectedInsulinTypes )
    {
	[selectedInsulinTypes removeAllObjects];
	if( type )
	    [selectedInsulinTypes addObject:type];
    }
    else if( type )
	selectedInsulinTypes = [NSMutableSet setWithObject:type];
}

- (void) setSelectedInsulinTypesWithArray:(NSOrderedSet*)types
{
    if( types.count )
	selectedInsulinTypes = [NSMutableSet setWithArray:[types array]];
    else
	selectedInsulinTypes = nil;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    if( multiCheck )
	[model flushInsulinTypesForNewEntries];
    [super viewWillDisappear:animated];
}

#pragma mark -

- (void) editRow
{
    NSIndexPath *const path = [NSIndexPath indexPathForRow:deleteRowNum inSection:0];
    TextFieldCell *const cell = (TextFieldCell*)[self.tableView cellForRowAtIndexPath:path];
    // Try again later if the row isn't visible yet
    if( cell )
	[cell.view becomeFirstResponder];
    else
	[self performSelector:@selector(editRow) withObject:nil afterDelay:0.1];
}

- (void) appendNewInsulinType
{
    const NSUInteger index = fetchedResultsController.fetchedObjects.count;

    [model addInsulinTypeWithName:nil];
    [model save];

    NSIndexPath *const path = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionNone animated:YES];
    deleteRowNum = index;	// Reuse deleteRowNum to avoid creating a new variable
    [self performSelector:@selector(editRow) withObject:nil afterDelay:0.2];
}

- (void) configureCell:(UITableViewCell*)cell indexPath:(NSIndexPath*)indexPath forInsulinType:(ManagedInsulinType*)insulinType
{
    // Put a checkmark on the currently selected row(s)
    if( [selectedInsulinTypes containsObject:insulinType] )
    {
	if( multiCheck )
	    cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
	    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else
	cell.accessoryType = UITableViewCellAccessoryNone;

    if( self.editing )
    {
	((TextFieldCell*)cell).editedObject = insulinType;
	((TextFieldCell*)cell).textField.text = [insulinType shortName];
	cell.accessibilityLabel = [insulinType shortName];

	// Highlight the row if its insulin type is on the list of types used for new entries
	if( NSNotFound != [model.insulinTypesForNewEntries indexOfObject:insulinType] )
	    ((TextFieldCell*)cell).textField.textColor = [UIColor blueColor];
	else
	    ((TextFieldCell*)cell).textField.textColor = [UIColor blackColor];
    }
    else
    {
	cell.textLabel.text = [insulinType shortName];
	cell.textLabel.textColor = [UIColor blackColor];
    }
}

- (void) deleteInsulinType:(ManagedInsulinType*)insulinType
{
    [model removeInsulinType:insulinType];
}

- (void) confirmDeleteInsulinType:(ManagedInsulinType*)insulinType
{
    const NSUInteger numRecords = [model numberOfLogEntriesForInsulinType:insulinType];
    // Ask the user for confirmation if numRecords != 0
    if( numRecords )
    {
	alertReason = ALERT_REASON_TYPE_NOT_EMPTY;
	deleteRowNum = index;
	deleteInsulinType = insulinType;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
							message:[NSString stringWithFormat:@"Deleting 'Insulin %@' will delete dose information from %lu log entr%@", insulinType.shortName, (unsigned long)numRecords, ((numRecords>1)?@"ies":@"y")]
						       delegate:self
					      cancelButtonTitle:@"Cancel"
					      otherButtonTitles:@"OK", nil];
	[alert show];
    }
    else
	[self deleteInsulinType:insulinType];
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
	    [self.tableView deleteRowsAtIndexPaths:@[indexPath]
				  withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeInsert:
	    [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
				  withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeMove:
	    if( !userDrivenChange )
	    {
		[self.tableView deleteRowsAtIndexPaths:@[indexPath]
				      withRowAnimation:UITableViewRowAnimationAutomatic];
		[self.tableView insertRowsAtIndexPaths:@[newIndexPath]
				      withRowAnimation:UITableViewRowAnimationAutomatic];
	    }
	    break;
	case NSFetchedResultsChangeUpdate:
	    if( !userDrivenChange )
	    {
		[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath]
			  indexPath:indexPath
		     forInsulinType:[fetchedResultsController objectAtIndexPath:indexPath]];
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
	default:
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

    return [[sections objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
    const NSInteger section = indexPath.section;
    NSString* cellID = self.editing && (section != kRestoreDefaultsSectionNumber) ? @"EditCellID" : @"Cell";

    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellID];
    if( !cell )
    {
	if( self.editing )
	{
	    switch( section )
	    {
		case kInsulinTypesSectionNumber:
		    cell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		    ((TextFieldCell*)cell).clearButtonMode = UITextFieldViewModeWhileEditing;
		    cell.showsReorderControl = YES;
		    ((TextFieldCell*)cell).delegate = self;
		    ((TextFieldCell*)cell).font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]+3];
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

    switch( section )
    {
	case kInsulinTypesSectionNumber:
	    [self configureCell:cell indexPath:indexPath forInsulinType:[fetchedResultsController objectAtIndexPath:indexPath]];
	    break;
	case kRestoreDefaultsSectionNumber:
	    cell.textLabel.text = @"Restore Default Types";
	    cell.textLabel.textAlignment = NSTextAlignmentCenter;
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
    {
	if( [self.delegate respondsToSelector:@selector(insulinTypeViewControllerDidSelectRestoreDefaults)] )
	    [self.delegate insulinTypeViewControllerDidSelectRestoreDefaults];
    }
    else
    {
	UITableViewCell *const cell = [tv cellForRowAtIndexPath:indexPath];
	ManagedInsulinType *const t = [fetchedResultsController objectAtIndexPath:indexPath];

	// Toggle the checkmark on the selected row and notify the delegate
	//  The delegate can block the selection event by returning NO
	if( UITableViewCellAccessoryNone == cell.accessoryType )
	{
	    if( [self.delegate respondsToSelector:@selector(insulinTypeViewControllerDidSelectInsulinType:)] )
		if( [self.delegate insulinTypeViewControllerDidSelectInsulinType:t] )
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
	    if( [self.delegate respondsToSelector:@selector(insulinTypeViewControllerDidUnselectInsulinType:)] )
		[self.delegate insulinTypeViewControllerDidUnselectInsulinType:t];
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
    if( (toPath.section == kInsulinTypesSectionNumber) && (toPath.row < fetchedResultsController.fetchedObjects.count) )
	return toPath;
    return [NSIndexPath indexPathForRow:(fetchedResultsController.fetchedObjects.count-1) inSection:kInsulinTypesSectionNumber];
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
	ManagedInsulinType* insulinType = [fetchedResultsController objectAtIndexPath:path];
	if( [model.insulinTypesForNewEntries containsObject:insulinType] )
	{
	    alertReason = ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE;
	    deleteRowNum = path.row;
	    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
							    message:[NSString stringWithFormat:@"'Insulin %@' is used for new log entries. If you delete this insulin type it will no longer be displayed for new log entries.", insulinType.shortName]
							   delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	    [alert show];
	}
	else	// Otherwise, carry on
	    [self confirmDeleteInsulinType:insulinType];
    }
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath
{
    userDrivenChange = YES;

    NSMutableArray* insulinTypes = [[fetchedResultsController fetchedObjects] mutableCopy];
    NSManagedObject* insulinType = [fetchedResultsController objectAtIndexPath:fromIndexPath];

    [insulinTypes removeObject:insulinType];
    [insulinTypes insertObject:insulinType atIndex:toIndexPath.row];

    unsigned index = 0;
    for( ManagedInsulinType* insulinType in insulinTypes )
	insulinType.sequenceNumber = [NSNumber numberWithInt:index++];

    [model save];

    userDrivenChange = NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( multiCheck )
	return @"Choose up to 2 insulin types to be automatically added to new log entries";
    else if( self.editing  && (section != kRestoreDefaultsSectionNumber) )
	return @"Add, delete, rename or reorder insulin types";
    return nil;
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
		[self confirmDeleteInsulinType:deleteInsulinType];
		break;
	    case ALERT_REASON_TYPE_NOT_EMPTY:
		[self deleteInsulinType:deleteInsulinType];
		break;
	}
    }
    else
	// Reload the table on cancel to work around a display bug
	[self.tableView reloadData];
}

#pragma mark - <TextFieldCellDelegate>

- (void)textFieldCellDidEndEditing:(TextFieldCell*)cell
{
    ManagedInsulinType* type = cell.editedObject;
    if( !type || !cell )
	return;
    type.shortName = (cell.text && cell.text.length) ? cell.text : nil;
    [model save];
}

@end
