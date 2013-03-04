#import "AppDelegate.h"
#import "Constants.h"
#import "FlurryLogger.h"

#import "Category.h"
#import "InsulinType.h"
#import "LogDay.h"
#import "LogEntry.h"
#import "LogModel.h"
#import "LogViewController.h"
#import "LogEntryCell.h"
#import "ManagedCategory.h"
#import "ManagedInsulinDose.h"
#import "ManagedInsulinType.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"
#import "SettingsViewController.h"

#define	ANIMATION_DURATION	    0.5	    // seconds

@interface LogViewController () <NSFetchedResultsControllerDelegate, SettingsViewControllerDelegate>

@property (nonatomic, weak) id<LogViewDelegate>   delegate;
@property (nonatomic, strong) LogModel*	model;
@property (nonatomic, strong) SettingsViewController* settingsViewController;

@end

@implementation LogViewController
{
    NSFetchedResultsController*	fetchedResultsController;
    NSDateFormatter*	shortDateFormatter;
    NSDateFormatter*	shortTimeFormatter;
}

@synthesize delegate = _delegate;
@synthesize model = _model;
@synthesize settingsViewController;

- (id)initWithModel:(LogModel*)model delegate:(id<LogViewDelegate>)delegate
{
    if( self = [super initWithStyle:UITableViewStylePlain] )
    {
	self.delegate = delegate;
	self.model = model;

	self.title = @"Glucose";

        UIButton* settingsButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[settingsButton addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
	settingsButton.accessibilityLabel = @"Settings";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];

	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStyleBordered target: nil action: nil];

	shortDateFormatter = [[NSDateFormatter alloc] init];
	shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
	shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
	shortDateFormatter.doesRelativeDateFormatting = YES;

	shortTimeFormatter = [[NSDateFormatter alloc] init];
	[shortTimeFormatter setTimeStyle:NSDateFormatterShortStyle];

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[model fetchRequestForOrderedLogEntries]
								       managedObjectContext:model.managedObjectContext
									 sectionNameKeyPath:@"logDay.date"
										  cacheName:nil];
	fetchedResultsController.delegate = self;

	NSError* error = nil;
	[fetchedResultsController performFetch:&error];
	if( error )
	    [FlurryLogger logError:@"Unresolved Error" message:[error localizedDescription] error:error];
    }
    return self;
}

- (void)viewDidLoad
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewEntry:)];
}

- (void) inspectLogEntry:(ManagedLogEntry*)entry
{
    LogEntryViewController* logEntryViewController;
    if( entry )
    {
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStyleBordered target: nil action: nil];

	logEntryViewController = [[LogEntryViewController alloc] initWithLogEntry:entry];
	logEntryViewController.model = _model;
    }
    else
    {
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target: nil action: nil];
	logEntryViewController = [[LogEntryViewController alloc] initWithLogModel:_model];
    }

    logEntryViewController.delegate = self;

    [self.navigationController pushViewController:logEntryViewController animated:YES];
}

- (void) showSettings:(id)sender
{
    if( !settingsViewController )
    {
	settingsViewController = [[SettingsViewController alloc] init];
	settingsViewController.delegate = self;
	settingsViewController.model = _model;
    }

	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:ANIMATION_DURATION];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
						   forView:self.navigationController.view cache:YES];
    [self.navigationController pushViewController:settingsViewController animated:NO];	
	[UIView commitAnimations];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

    // Update the LogEntryCell class width trackers
    [LogEntryCell setInsulinTypeShortNameWidth:_model.insulinTypeShortNameMaxWidth];
    [LogEntryCell setCategoryNameWidth:_model.categoryNameMaxWidth];
}

// Invoked when the user touches Edit.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    // Updates the appearance of the Edit|Done button as necessary.
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
    // Disable the add button while editing.
    if (editing) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void) addNewEntry:(id)sender
{
    [self inspectLogEntry:nil];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch( type )
    {
	case NSFetchedResultsChangeDelete:
	    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeInsert:
	    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeMove:
	    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	    break;
	case NSFetchedResultsChangeUpdate:
	{
	    LogEntryCell* cell = (LogEntryCell*)[self.tableView cellForRowAtIndexPath:indexPath];
	    ManagedLogEntry* logEntry = [fetchedResultsController objectAtIndexPath:indexPath];
	    [self configureCell:cell forLogEntry:logEntry];
	}
	default:
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
    [self.tableView endUpdates];
}

#pragma mark <UITableViewDataSource>

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return MAX(1, fetchedResultsController.sections.count);
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* sections = fetchedResultsController.sections;
    if( 0 == sections.count )
	return 0;
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray* sections = [fetchedResultsController sections];
    if( 0 == sections.count )
	return @"Today";

    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    ManagedLogEntry* logEntry = [[sectionInfo objects] lastObject];
    ManagedLogDay* logDay = logEntry.logDay;
    NSString* dateString = [shortDateFormatter stringFromDate:logDay.date];

    // Don't display the average if it's zero
    if( logDay.averageGlucose && ![logDay.averageGlucose isEqualToNumber:@0] )
	return [NSString stringWithFormat:@"%@ (%@)", dateString, [_model.averageGlucoseFormatter stringFromNumber:logDay.averageGlucose]];
    return dateString;
}

- (void) configureCell:(LogEntryCell*)cell forLogEntry:(ManagedLogEntry*)logEntry
{
    // Configure the cell
    cell.labelTimestamp.text = [shortTimeFormatter stringFromDate:logEntry.timestamp];
    cell.labelCategory.text = logEntry.category ? logEntry.category.name : @"";
    cell.labelGlucose.text = logEntry.glucoseString;
    cell.note = logEntry.note;

    // Color the glucose values accordingly
    const float glucose = [logEntry.glucose floatValue];

    if( glucose > [_model highGlucoseWarningThreshold] )
	cell.labelGlucose.textColor = [UIColor blueColor];
    else if( glucose < [_model lowGlucoseWarningThreshold] )
	cell.labelGlucose.textColor = [UIColor redColor];
    else
	cell.labelGlucose.textColor = [UIColor darkTextColor];

    if( logEntry.insulinDoses.count )
    {
	ManagedInsulinDose* insulinDose = [logEntry.insulinDoses objectAtIndex:0];
	cell.labelDose0.text = [insulinDose.quantity stringValue];
	cell.labelType0.text = insulinDose.insulinType.shortName;
    }

    if( logEntry.insulinDoses.count > 1 )
    {
	ManagedInsulinDose* insulinDose = [logEntry.insulinDoses objectAtIndex:1];
	cell.labelDose1.text = [insulinDose.quantity stringValue];
	cell.labelType1.text = insulinDose.insulinType.shortName;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LogEntryCell* cell = (LogEntryCell*)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([LogEntryCell class])];
    if( !cell )
    {
	cell = [[LogEntryCell alloc] initWithStyle:UITableViewCellStyleDefault
				   reuseIdentifier:NSStringFromClass([LogEntryCell class])];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    [self configureCell:cell
	    forLogEntry:[fetchedResultsController objectAtIndexPath:indexPath]];

    return cell;
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path
{
    [self inspectLogEntry:[fetchedResultsController objectAtIndexPath:path]];
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If the row was deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
	ManagedLogEntry* logEntry = [fetchedResultsController objectAtIndexPath:indexPath];
	[_model deleteLogEntry:logEntry
		       fromDay:logEntry.logDay];
	[_model commitChanges];
    }
}

#pragma mark - <LogEntryViewDelegate>

- (void) logEntryView:(LogEntryViewController*)view didEndEditingEntry:(ManagedLogEntry*)logEntry
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark <SettingsViewControllerDelegate>

- (void) settingsViewControllerDidChangeGlucoseUnits
{
    [self.tableView reloadData];
}

- (void) settingsViewControllerDidPressBack
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:ANIMATION_DURATION];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
			   forView:self.navigationController.view
			     cache:YES];
    [self.navigationController popViewControllerAnimated:NO];
    [UIView commitAnimations];
}

@end
