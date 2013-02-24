#import "AppDelegate.h"
#import "Constants.h"

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

@interface LogViewController () <SettingsViewControllerDelegate>

@property (nonatomic, weak) id<LogViewDelegate>   delegate;
@property (nonatomic, strong) LogModel*	model;
@property (nonatomic, strong) SettingsViewController* settingsViewController;

@end

@implementation LogViewController
{
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

#pragma mark <UITableViewDataSource>

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return MAX(1, _model.logDays.count);
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( 0 == _model.logDays.count )
	return 0;
    ManagedLogDay* logDay = [_model.logDays objectAtIndex:section];
    return logDay.logEntries.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( 0 == _model.logDays.count )
	return @"Today";

    ManagedLogDay* logDay = [_model.logDays objectAtIndex:section];
    NSString* dateString = [shortDateFormatter stringFromDate:logDay.date];

    // Don't display the average if it's zero
    if( logDay.averageGlucose && ![logDay.averageGlucose isEqualToNumber:@0] )
	return [NSString stringWithFormat:@"%@ (%@)", dateString, [_model.averageGlucoseFormatter stringFromNumber:logDay.averageGlucose]];
    return dateString;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = @"CellID";
    const unsigned section = indexPath.section;
    const unsigned row = indexPath.row;

    LogEntryCell *cell = (LogEntryCell*)[tableView dequeueReusableCellWithIdentifier:cellID];
    if( nil == cell )
    {
	cell = [[LogEntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    // Get the LogEntry for the cell
    ManagedLogDay* logDay = [_model.logDays objectAtIndex:section];
    ManagedLogEntry* logEntry = [logDay.logEntries objectAtIndex:row];

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
	cell.labelDose0.text = [insulinDose.dose stringValue];
	cell.labelType0.text = insulinDose.insulinType.shortName;
    }

    if( logEntry.insulinDoses.count > 1 )
    {
	ManagedInsulinDose* insulinDose = [logEntry.insulinDoses objectAtIndex:1];
	cell.labelDose1.text = [insulinDose.dose stringValue];
	cell.labelType1.text = insulinDose.insulinType.shortName;
    }
    return cell;
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path
{
    ManagedLogDay *const logDay = [_model.logDays objectAtIndex:path.section];
    [self inspectLogEntry:[logDay.logEntries objectAtIndex:path.row]];
}

- (void)tableView:(UITableView *)tv willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)path
{
    // If the requested row is in the last loaded section, schedule a task to load the next section
    const unsigned numberOfSections = [tv numberOfSections];
    if( (numberOfSections == (path.section + 1)) && (path.row == 0) )
    {
	if( numberOfSections < _model.logDays.count )
	    [self performSelectorOnMainThread:@selector(loadNextSection) withObject:nil waitUntilDone:NO];
    }
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If the row was deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
	ManagedLogDay *const logDay = [_model.logDays objectAtIndex:indexPath.section];
	if( 1 == logDay.logEntries.count )	// If the section is about to be empty, delete it
	{
	    [_model deleteLogDay:logDay];

	    // This must be called after deleting the section, otherwise UITableView will throw an exception
	    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
	}
	else
	{
	    [_model deleteLogEntry:[logDay.logEntries objectAtIndex:indexPath.row]
			   fromDay:logDay];

	    // This must be called after deleting the row, otherwise UITableView will throw an exception
	    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
    }
}

#pragma mark - <LogEntryViewDelegate>

- (void) logEntryViewControllerDidCancelEditing
{
    [self.model undo];
    [self.tableView reloadData];
}

- (void) logEntryView:(LogEntryViewController*)view didEndEditingEntry:(ManagedLogEntry*)logEntry
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.tableView reloadData];
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
