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

@interface LogViewController ()

@property (nonatomic, readonly)	AppDelegate*	appDelegate;
@property (nonatomic, retain)	NSDateFormatter*	dateFormatter;
@property (nonatomic, readonly) NSNumberFormatter* glucoseFormatter;
@property (nonatomic, retain) SettingsViewController* settingsViewController;

@end

@implementation LogViewController

@synthesize appDelegate, dateFormatter, glucoseFormatter;
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

		// A number formatter for glucose measurements
		glucoseFormatter = [[NSNumberFormatter alloc] init];
		[glucoseFormatter setMaximumFractionDigits:1];

		// Register to be notified whenever the sections array changes
		[appDelegate addObserver:self forKeyPath:@"sections" 
						 options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
		[appDelegate addObserver:self forKeyPath:@"entries" 
						 options:0 context:nil];
	}
	return self;
}

- (void)dealloc
{
//    [tableView release];
	[logEntryViewController release];
	[super dealloc];
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
        // Test the type of change. Insertions of new data receive special handling.
        if( kind == NSKeyValueChangeInsertion )
		{
			// Extract the section and row that changed
			const unsigned sectionIndex = [[change valueForKey:NSKeyValueChangeIndexesKey] firstIndex];
//			NSUInteger row = [[change valueForKey:NSKeyValueChangeIndexesKey] lastIndex];
			LogDay *const section = [appDelegate.sections objectAtIndex:sectionIndex];
			LogEntry *const entry = [section.entries objectAtIndex:0];
            [self inspectLogEntry:entry inSection:section setEditing:YES];	// Display an editing view for the new LogEntry
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationFade];
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

#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [appDelegate.sections count] ? [appDelegate.sections count] : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if( ![appDelegate.sections count] )
		return 0;
	LogDay *const s = [appDelegate.sections objectAtIndex:section];
	return s.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if( ![appDelegate.sections count] )
		return @"Today";

	LogDay *const s = [appDelegate.sections objectAtIndex:section];

	float averageGlucose = s.averageGlucose;
	NSString* avg = @"";
	if( averageGlucose != 0 )
		avg = [NSString stringWithFormat:@" (%@)", [glucoseFormatter stringFromNumber:[NSNumber numberWithFloat:averageGlucose]],nil];

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"CellID";
	
	LogEntryCell *cell = (LogEntryCell*)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if( nil == cell )
	{
		cell = [[[LogEntryCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	// Get the LogEntry for the cell
	LogDay *const s = [self.appDelegate.sections objectAtIndex:indexPath.section];
	if( s && s.count && ![s.entries count] )
		[s hydrate:appDelegate.database];
	LogEntry* entry = [s.entries objectAtIndex:indexPath.row];

	// Configure the cell
//	cell.entry = entry;
	cell.labelTimestamp.text = [dateFormatter stringFromDate:entry.timestamp];
	cell.labelCategory.text = entry.category ? entry.category.categoryName : @"";
	[glucoseFormatter setPositiveSuffix:entry.glucoseUnits];
	[glucoseFormatter setNegativeSuffix:entry.glucoseUnits];
	cell.labelGlucose.text = entry.glucose ? [glucoseFormatter stringFromNumber:entry.glucose] : nil;
	cell.note = entry.note;

	// Color the glucose values accordingly
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	if( [entry.glucose compare:[NSNumber numberWithFloat:[defaults floatForKey:kHighGlucoseWarning0]]] == NSOrderedDescending )
		cell.labelGlucose.textColor = [UIColor blueColor];
	else if( [entry.glucose compare:[NSNumber numberWithFloat:[defaults floatForKey:kLowGlucoseWarning0]]] == NSOrderedAscending )
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	LogDay *const s = [self.appDelegate.sections objectAtIndex:indexPath.section];
	[self inspectLogEntry:[s.entries objectAtIndex:indexPath.row]
				inSection:s];
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If row is deleted, remove it from the list.
    if( editingStyle == UITableViewCellEditingStyleDelete )
	{
        if( ![appDelegate deleteLogEntryAtIndexPath:indexPath] )
			[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end

