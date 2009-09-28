//
//  LogViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 6/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogDay.h"
#import "LogViewController.h"
#import "LogEntryCell.h"
#import "SettingsViewController.h"

static AppDelegate *appDelegate = nil;

@interface LogViewController ()

@property (nonatomic, retain)	NSDateFormatter*	dateFormatter;
@property (nonatomic, retain) SettingsViewController* settingsViewController;

@end

@implementation LogViewController

@synthesize dateFormatter;
@synthesize logEntryViewController, settingsViewController;

- (id)initWithStyle:(UITableViewStyle)style
{
	if( self = [super initWithStyle:style] )
	{
		self.title = @"Log";
		appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        UIButton* b = [UIButton buttonWithType:UIButtonTypeInfoLight];
		[b addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:b];
		[b release];


		// Create a date formatter to convert the date to a string format.
		self.dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];

		// Register to be notified whenever the sections array changes
		[appDelegate addObserver:self forKeyPath:@"sections" 
						 options:0 context:nil];
		[appDelegate addObserver:self forKeyPath:@"entries" 
						 options:NSKeyValueObservingOptionOld context:nil];
	}
	return self;
}

- (void)dealloc
{
//    [tableView release];
	[logEntryViewController release];
	[super dealloc];
}

- (void)viewDidLoad
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewEntry:)];
}

/*
- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}
*/
// Handle change notifications for observed key paths of other objects.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqual:@"sections"] )
	{
		const int kind = [[change valueForKey:NSKeyValueChangeKindKey] intValue];
		NSIndexSet *const indexSet = [change valueForKey:NSKeyValueChangeIndexesKey];
		[indexSet retain];
		switch( kind )
		{
			case NSKeyValueChangeInsertion:
				[self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
				break;
			case NSKeyValueChangeRemoval:
				[self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
				break;
		}
    }
	else if( [keyPath isEqual:@"entries"] )
	{
		const int kind = [[change valueForKey:NSKeyValueChangeKindKey] intValue];
		NSIndexSet *const indexSet = [change valueForKey:NSKeyValueChangeIndexesKey];
		const unsigned sectionIndex = [indexSet firstIndex];	// Get the section that changed

		switch( kind )
		{
			case NSKeyValueChangeInsertion:
				[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationFade];
				LogDay *const section = [appDelegate.sections objectAtIndex:sectionIndex];
				LogEntry *const entry = [section.entries objectAtIndex:0];
				[self inspectLogEntry:entry inSection:section setEditing:YES];	// Display an editing view for the new LogEntry
				break;
			case NSKeyValueChangeRemoval:
			{
				NSNumber *const row = [[change valueForKey:NSKeyValueChangeOldKey] anyObject];
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[row intValue] inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationFade];
				break;
			}
		}
	}
    // Verify that the superclass does indeed handle these notifications before actually invoking that method.
	else if( [[self superclass] instancesRespondToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)] )
	{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section;
{
	[self inspectLogEntry:entry inSection:section setEditing:NO];
}

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section setEditing:(BOOL)e
{
    // Create the detail view lazily
    if( !logEntryViewController )
        logEntryViewController = [[LogEntryViewController alloc] initWithStyle:UITableViewStyleGrouped];

//    [entry hydrate];		// Force the LogEntry to be fully loaded from the database
    logEntryViewController.entry = entry;	// Give the view controller the LogEntry to display
	logEntryViewController.entrySection = section;
    // Push the detail view on to the navigation controller's stack.
    [self.navigationController pushViewController:logEntryViewController animated:YES];
    [logEntryViewController setEditing:e animated:NO];
}

- (void) showSettings:(id)sender
{
	if( !settingsViewController )
		settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.75];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
						   forView:self.navigationController.view cache:YES];
    [self.navigationController pushViewController:settingsViewController animated:NO];	
	[UIView commitAnimations];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
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
    // Create a new record in the database and get its automatically generated primary key.
    sqlite3 *const db = appDelegate.database;
    unsigned entryID = [LogEntry insertNewLogEntryIntoDatabase:db];
    LogEntry* entry = [[LogEntry alloc] initWithID:entryID database:db];

    // Set defaults for the new LogEntry
    NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
    /*	Don't use the returned string directly because glucoseUnits is used 
	elsewhere in pointer comparisons (for performance reasons). 
	Consequently, it must be a pointer to one of the constants in 
	Constants.h.   */
    if( [[defaults objectForKey:kDefaultGlucoseUnits] isEqualToString:kGlucoseUnits_mgdL] )
	entry.glucoseUnits = kGlucoseUnits_mgdL;
    else
	entry.glucoseUnits = kGlucoseUnits_mmolL;
    
    [self inspectLogEntry:entry inSection:nil setEditing:YES];	// Display an editing view for the new LogEntry
}

#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [appDelegate.sections count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // If the table hasn't been fully loaded the last section has an extra row for loading more rows
    if( partialTableLoad && (section == ([appDelegate.sections count]-1)) )
	return [[appDelegate.sections objectAtIndex:section] count] + 1;
	LogDay *const s = [appDelegate.sections objectAtIndex:section];
	return s.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	LogDay *const s = [appDelegate.sections objectAtIndex:section];

    const float averageGlucose = s.averageGlucose;
	NSString* avg = @"";
	if( averageGlucose != 0 )
    {
	// Use the units from the section's first entry and hope the user
	//  hasn't been switching units within a section
	NSString *const units = [[s.entries objectAtIndex:0] glucoseUnits];
	const unsigned precision = (units == kGlucoseUnits_mgdL) ? 0 : 1;
	avg = [NSString localizedStringWithFormat:@" (%.*f%@)", precision, averageGlucose, units];
    }

	// Only the first section could possibly be the "today" section
	//  So return SectionName for all but the first section
	if( section )
		return [NSString stringWithFormat:@"%@%@", s.name, avg, nil];

	// Make sure it really is today
	NSCalendar *const calendar = [NSCalendar currentCalendar];
	static const unsigned components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *const today = [calendar components:components fromDate:[NSDate date]];
	NSDateComponents *const c = [calendar components:components fromDate:s.date];
	if( (today.day == c.day) && (today.month == c.month) && (today.year == c.year) )
		return [NSString stringWithFormat:@"%@%@", @"Today", avg, nil];

	return [NSString stringWithFormat:@"%@%@", s.name, avg, nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = @"CellID";
    const unsigned section = indexPath.section;
    const unsigned row = indexPath.row;

    if( (section == ([appDelegate.sections count]-1)) && (row == [[appDelegate.sections objectAtIndex:section] count]) )
	cellID = @"MoreCell";

    LogEntryCell *cell = (LogEntryCell*)[tableView dequeueReusableCellWithIdentifier:cellID];
    if( nil == cell )
    {
	if( @"MoreCell" == cellID )
	    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	else
	{
	    cell = [[[LogEntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
    }

    if( @"MoreCell" == cellID )
    {
	cell.textLabel.text = @"Display More Log Entries";
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	return cell;
    }

	// Get the LogEntry for the cell
	LogDay *const s = [appDelegate.sections objectAtIndex:indexPath.section];
	if( s && s.count && ![s.entries count] )
		[s hydrate:appDelegate.database];
	LogEntry* entry = [s.entries objectAtIndex:indexPath.row];

	// Configure the cell
//	cell.entry = entry;
	cell.labelTimestamp.text = [dateFormatter stringFromDate:entry.timestamp];
	cell.labelCategory.text = entry.category ? entry.category.categoryName : @"";
    NSString *const units = entry.glucoseUnits;
    const unsigned precision = (units == kGlucoseUnits_mgdL) ? 0 : 1;
    cell.labelGlucose.text = entry.glucose ? [NSString localizedStringWithFormat:@"%.*f%@", precision, [entry.glucose floatValue], units] : nil;
	cell.note = entry.note;

	// Color the glucose values accordingly
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
    NSString* keyHigh;
    NSString* keyLow;
    if( units == kGlucoseUnits_mgdL )
    {
	keyHigh = kHighGlucoseWarning0;
	keyLow = kLowGlucoseWarning0;
    }
    else
    {
	keyHigh = kHighGlucoseWarning1;
	keyLow = kLowGlucoseWarning1;
    }
    if( [entry.glucose floatValue] > [defaults floatForKey:keyHigh] )
		cell.labelGlucose.textColor = [UIColor blueColor];
    else if( [entry.glucose floatValue] < [defaults floatForKey:keyLow] )
		cell.labelGlucose.textColor = [UIColor redColor];
	else
		cell.labelGlucose.textColor = [UIColor darkTextColor];

	InsulinDose* dose = [entry.insulin count] ? [entry.insulin objectAtIndex:0] : nil;
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
	dose = ([entry.insulin count] > 1) ? [entry.insulin objectAtIndex:1] : nil;
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
    LogDay *const s = [appDelegate.sections objectAtIndex:section];

    // HI guidlines say row should be selected and then deselected
    [tv deselectRowAtIndexPath:path animated:YES];

    if( (section == ([appDelegate.sections count]-1)) && (row == [s count]) )
    {
	[appDelegate.sections addObjectsFromArray:[LogDay loadSections:appDelegate.database limit:30 offset:[appDelegate.sections count]]];
	partialTableLoad = [LogDay numberOfDays:appDelegate.database] > [appDelegate.sections count];
	[tv reloadData];
    }
    else
	[self inspectLogEntry:[s.entries objectAtIndex:row] inSection:s];
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If the row was deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
		[appDelegate deleteLogEntryAtIndexPath:indexPath];
}

@end

