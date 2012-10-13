#import "TextFieldCell.h"

#import "AppDelegate.h"
#import "InsulinType.h"
#import "InsulinTypeViewController.h"
#import "LogEntry.h"
#import "LogModel.h"

#define	kInsulinTypesSectionNumber		0
#define	kRestoreDefaultsSectionNumber		1

@implementation InsulinTypeViewController
{
    NSMutableSet*	selectedInsulinTypes;
}
@synthesize delegate;
@synthesize model;
@synthesize multiCheck;

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style])
    {
	self.title = @"Insulin Types";
	dirty = NO;
	multiCheck = NO;
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) setEditing:(BOOL)e animated:(BOOL)animated
{
    [super setEditing:e animated:animated];
    // Flush the category array to the database if it has been modified
    if( dirty )
    {
	dirty = NO;
    }
    // Eanble the Add button while editing
    if( e )
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(appendNewInsulinType)];
    else
	self.navigationItem.rightBarButtonItem = nil;
    [self.tableView reloadData];
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
	selectedInsulinTypes = [NSMutableSet setWithObject:type];
}

- (void) setSelectedInsulinTypesWithArray:(NSArray*)types
{
    if( selectedInsulinTypes )
    {
	[selectedInsulinTypes removeAllObjects];
	[selectedInsulinTypes addObjectsFromArray:types];
    }
    else
	selectedInsulinTypes = [NSMutableSet setWithArray:types];
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
	if( [delegate respondsToSelector:@selector(insulinTypeViewControllerDidEndMultiSelect)] )
	    [delegate insulinTypeViewControllerDidEndMultiSelect];
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
    if( [delegate respondsToSelector:@selector(insulinTypeViewControllerCreateInsulinType)] )
    {
	const unsigned index = [model.insulinTypes count];
	[delegate insulinTypeViewControllerCreateInsulinType];
	NSIndexPath *const path = [NSIndexPath indexPathForRow:index inSection:0];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:path]
			      withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionNone animated:YES];
	deleteRowNum = index;	// Reuse deleteRowNum to avoid creating a new variable
	[self performSelector:@selector(editRow) withObject:nil afterDelay:0.2];
    }
}

- (void) deleteInsulinTypeAtIndex:(unsigned)index
{
    if( [delegate respondsToSelector:@selector(insulinTypeViewControllerDidDeleteInsulinType:)] )
    {
	InsulinType *const type = [model.insulinTypes objectAtIndex:index];
	[delegate insulinTypeViewControllerDidDeleteInsulinType:type];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]]
			      withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void) confirmDeleteInsulinTypeAtIndex:(unsigned)index
{
    InsulinType *const type = [model.insulinTypes objectAtIndex:index];
    const unsigned numRecords = [appDelegate numLogEntriesForInsulinTypeID:type.typeID];
    // Ask the user for confirmation if numRecords != 0
    if( numRecords )
    {
	alertReason = ALERT_REASON_TYPE_NOT_EMPTY;
	deleteRowNum = index;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
							message:[NSString stringWithFormat:@"Deleting 'Insulin %@' will delete dose information from %u log entr%@", type.shortName, numRecords, ((numRecords>1)?@"ies":@"y")]
						       delegate:self
					      cancelButtonTitle:@"Cancel"
					      otherButtonTitles:@"OK", nil];
	[alert show];
    }
    else
	[self deleteInsulinTypeAtIndex:index];
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

    return [model.insulinTypes count];
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
	{
	    // Get the row's insulin type object
	    InsulinType *const type = [model.insulinTypes objectAtIndex:indexPath.row];

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
		cell.accessibilityLabel = [type shortName];

		// Highlight the row if its insulin type is on the list of types used for new entries
		if( NSNotFound != [model.insulinTypesForNewEntries indexOfObjectIdenticalTo:type] )
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
    {
	if( [delegate respondsToSelector:@selector(insulinTypeViewControllerDidSelectRestoreDefaults)] )
	{
	    [delegate insulinTypeViewControllerDidSelectRestoreDefaults];
	    [self.tableView reloadData];
	}
    }
    else
    {
	UITableViewCell *const cell = [tv cellForRowAtIndexPath:indexPath];
	InsulinType *const t = [model.insulinTypes objectAtIndex:indexPath.row];

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
    if( toPath.row < [model.insulinTypes count] )
	return toPath;
    return [NSIndexPath indexPathForRow:([model.insulinTypes count]-1) inSection:toPath.section];
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
	InsulinType *const type = [model.insulinTypes objectAtIndex:path.row];
	if( NSNotFound != [model.insulinTypesForNewEntries indexOfObjectIdenticalTo:type] )
	{
	    alertReason = ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE;
	    deleteRowNum = path.row;
	    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
							    message:[NSString stringWithFormat:@"'Insulin %@' is used for new log entries. If you delete this insulin type it will no longer be displayed for new log entries.", type.shortName]
							   delegate:self
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:@"OK", nil];
	    [alert show];
	}
	else	// Otherwise, carry on
	    [self confirmDeleteInsulinTypeAtIndex:path.row];
    }
}

- (void) tableView:(UITableView*)tv moveRowAtIndexPath:(NSIndexPath*)fromPath toIndexPath:(NSIndexPath*)toPath
{
    [model moveInsulinTypeAtIndex:fromPath.row toIndex:toPath.row];
    dirty = YES;
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
		[self confirmDeleteInsulinTypeAtIndex:deleteRowNum];
		break;
	    case ALERT_REASON_TYPE_NOT_EMPTY:
		[self deleteInsulinTypeAtIndex:deleteRowNum];
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
    InsulinType* type = cell.editedObject;
    if( !type || !cell )
	return;
    type.shortName = (cell.text && cell.text.length) ? cell.text : nil;
    [model updateInsulinType:type];
}

@end
