#import "AppDelegate.h"
#import "Constants.h"

#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogDay.h"
#import "LogEntry.h"
#import "LogModel.h"
#import "LogViewController.h"
#import "LogEntryCell.h"
#import "SettingsViewController.h"

#define	ANIMATION_DURATION	    0.5	    // seconds

@interface LogViewController () <SettingsViewControllerDelegate>

@property (nonatomic, retain)	NSDateFormatter*	dateFormatter;
@property (nonatomic, assign) id<LogViewDelegate>   delegate;
@property (nonatomic, retain) LogModel*	model;
@property (nonatomic, retain) SettingsViewController* settingsViewController;

@end

@implementation LogViewController

@synthesize dateFormatter;
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

        UIButton* b = [[UIButton buttonWithType:UIButtonTypeInfoLight] retain];
		[b addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:b];
		[b release];

	UIBarButtonItem* back = [[UIBarButtonItem alloc] initWithTitle: @"Log" style:UIBarButtonItemStyleBordered target: nil action: nil];
	self.navigationItem.backBarButtonItem = back;
	[back release];

		// Create a date formatter to convert the date to a string format.
		self.dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	return self;
}

- (void)dealloc
{
    self.model = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewEntry:)];
}

- (void) inspectNewLogEntry:(LogEntry*)entry
{
    [self inspectLogEntry:entry inSection:nil setEditing:YES isNew:YES];
}

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section;
{
    [self inspectLogEntry:entry inSection:section setEditing:NO isNew:NO];
}

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section setEditing:(BOOL)e isNew:(BOOL)n
{
    LogEntryViewController* logEntryViewController = [[LogEntryViewController alloc] initWithLogEntry:entry];
    logEntryViewController.delegate = self;
    logEntryViewController.model = _model;
    logEntryViewController.entrySection = section;

    // Push the detail view on to the navigation controller's stack.
    [self.navigationController pushViewController:logEntryViewController animated:YES];
    logEntryViewController.editingNewEntry = n;
    [logEntryViewController setEditing:e animated:NO];
    [logEntryViewController release];
}

- (void) showSettings:(id)sender
{
    if( !settingsViewController )
    {
	settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
	[self.tableView reloadData];

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
    // Create a new record
    LogEntry *const entry = [_model createLogEntry];

    // Display the detail view so the user can edit the new entry
    if( entry )
	[self inspectNewLogEntry:entry];
}

// Force the delegate to load another section and then tell the UITableView about it
- (void) loadNextSection
{
    const unsigned count = [_model numberOfLoadedLogDays];
    NSLog(@"Loading day %d", count);
    if( [_model logDayAtIndex:count] )
	[self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(count,1)]
		      withRowAnimation:NO];
}

#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    const unsigned numLoaded = [_model numberOfLoadedLogDays];

    /* Schedule a section load if nothing has been loaded yet
	This should never happen because the AppDelegate ensures that there is 
	always at least one day loaded, even if it's empty.	*/
    if( 0 == numLoaded )
	[self performSelectorOnMainThread:@selector(loadNextSection) withObject:nil waitUntilDone:NO];

    return numLoaded;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_model numberOfEntriesForLogDayAtIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    LogDay *const day = [_model logDayAtIndex:section];

    /* Display "Today" instead of the date string if the LogDay corresponds to
	the current date. Only the first section could possibly be the "today"
	section, so don't bother checking the others.	*/
    NSString* name = day.name;
    if( 0 == section )
    {
	// Make sure it really is today
	NSCalendar *const calendar = [NSCalendar currentCalendar];
	static const unsigned components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *const today = [calendar components:components fromDate:[NSDate date]];
	NSDateComponents *const c = [calendar components:components fromDate:day.date];
	if( (today.day == c.day) && (today.month == c.month) && (today.year == c.year) )
	    name = @"Today";
    }

    NSString *const average = day.averageGlucoseString;

    // Don't display the average if it's zero
    NSString *const format = average ? @"%@ (%@)" : @"%@";

    return [NSString stringWithFormat:format, name, average, nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = @"CellID";
    const unsigned section = indexPath.section;
    const unsigned row = indexPath.row;

    LogEntryCell *cell = (LogEntryCell*)[tableView dequeueReusableCellWithIdentifier:cellID];
    if( nil == cell )
    {
	cell = [[[LogEntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    // Get the LogEntry for the cell
    LogEntry *const entry = [_model logEntryAtIndex:row inDayIndex:section];

	// Configure the cell
//	cell.entry = entry;
	cell.labelTimestamp.text = [dateFormatter stringFromDate:entry.timestamp];
	cell.labelCategory.text = entry.category ? entry.category.categoryName : @"";
    cell.labelGlucose.text = entry.glucoseString;
	cell.note = entry.note;

	// Color the glucose values accordingly
    NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
    const float glucose = [entry.glucose floatValue];
    float thresholdHigh, threshholdLow;
    if( kGlucoseUnits_mgdL == entry.glucoseUnits )
    {
	thresholdHigh = [defaults floatForKey:kHighGlucoseWarning0];
	threshholdLow = [defaults floatForKey:kLowGlucoseWarning0];
    }
    else
    {
	thresholdHigh = [defaults floatForKey:kHighGlucoseWarning1];
	threshholdLow = [defaults floatForKey:kLowGlucoseWarning1];
    }
    if( glucose > thresholdHigh )
	cell.labelGlucose.textColor = [UIColor blueColor];
    else if( glucose < threshholdLow )
	cell.labelGlucose.textColor = [UIColor redColor];
    else
	cell.labelGlucose.textColor = [UIColor darkTextColor];

	InsulinDose* dose = [entry doseAtIndex:0];
	if( dose && dose.dose && dose.type )
	{
		cell.labelDose0.text = [dose.dose stringValue];
		cell.labelType0.text = dose.type.shortName;
	}
	else
	{
		cell.labelDose0.text = nil;
		cell.labelType0.text = nil;
	}
	dose = [entry doseAtIndex:1];
	if( dose && dose.dose && dose.type )
	{
		cell.labelDose1.text = [dose.dose stringValue];
		cell.labelType1.text = dose.type.shortName;
	}
	else
	{
		cell.labelDose1.text = nil;
		cell.labelType1.text = nil;
	}
	
	return cell;
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)path
{
    const unsigned section = path.section;
    const unsigned row = path.row;

    // HI guidlines say row should be selected and then deselected
    [tv deselectRowAtIndexPath:path animated:YES];

    LogDay *const s = [_model logDayAtIndex:section];

    [self inspectLogEntry:[s.entries objectAtIndex:row] inSection:s];
}

- (void)tableView:(UITableView *)tv willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)path
{
    // If the requested row is in the last loaded section, schedule a task to load the next section
    const unsigned numberOfSections = [tv numberOfSections];
    if( (numberOfSections == (path.section + 1)) && (path.row == 0) )
    {
	if( numberOfSections < [_model numberOfLogDays] )
	    [self performSelectorOnMainThread:@selector(loadNextSection) withObject:nil waitUntilDone:NO];
    }
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If the row was deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
    {
	LogDay *const day = [_model logDayAtIndex:indexPath.section];
	if( 1 == [day count] )	// If the section is about to be empty, delete it
	{
	    [_model deleteLogDay:day];

	    // This must be called after deleting the section, otherwise UITableView will throw an exception
	    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
	}
	else
	{
	    [_model deleteLogEntry:[_model logEntryAtIndex:indexPath.row inDay:day]
			     inDay:day];

	    // This must be called after deleting the row, otherwise UITableView will throw an exception
	    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
    }
}

#pragma mark -
#pragma mark <LogEntryViewDelegate>

- (void) logEntryView:(LogEntryViewController*)view didEndEditingEntry:(LogEntry*)entry
{
    if( entry.dirty )
    {
	LogDay *const newDay = [_model logDayForDate:entry.timestamp];
	if ( newDay != view.entrySection )
	{
	    [_model moveLogEntry:entry
			 fromDay:view.entrySection
			   toDay:newDay];
	    view.entrySection = newDay;
	}
	else	// Only need to update if above block was skipped
	    [newDay updateStatistics];
	[entry flush:_model.database];
    }
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
