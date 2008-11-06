//
//  AppDelegate.m
//  Glucose
//
//  Created by Brandon Fosdick on 6/27/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "AppDelegate.h"
#import "Category.h"
#import "Constants.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogEntry.h"
#import "LogDay.h"
#import "CategoryViewController.h"
#import "InsulinTypeViewController.h"
#import "LogViewController.h"

#import "GDataDocs.h"

#define	LOG_SQL		@"glucose.sqlite"

@interface AppDelegate (Private)
- (void) createEditableCopyOfDatabaseIfNeeded;
- (BOOL) openLogDatabase;
- (void) closeLogDatabase;

- (void) loadCategories;
- (void) loadDefaultInsulinTypes;
- (void) loadInsulinTypes;
- (void) loadAllSections;
@end

@implementation AppDelegate

@synthesize window;
@synthesize navController;
@synthesize categories, defaultInsulinTypes, insulinTypes;
@synthesize categoryViewController, insulinTypeViewController;
@synthesize logViewController;
@synthesize sections;
@synthesize database;
@synthesize docService;

NSDateFormatter* shortDateFormatter = nil;

unsigned maxCategoryNameWidth = 0;
unsigned maxInsulinTypeShortNameWidth = 0;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{	
    // Create the top level window (instead of using a default nib)
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// Set the background color for the flip animation going to/from the settings view
	//  The background color is what shows up behind the flipping views
	window.backgroundColor = [UIColor blackColor];
	
	// Register default defaults
	NSArray* a = [NSArray arrayWithObjects:[NSNumber numberWithInt:6], [NSNumber numberWithInt:1], nil];	// NPH, Aspart
	NSArray* keys = [NSArray arrayWithObjects:kHighGlucoseWarning0, kLowGlucoseWarning0, kHighGlucoseWarning1, kLowGlucoseWarning1, kDefaultGlucoseUnits, kDefaultInsulinTypes, nil];
	NSArray* values = [NSArray arrayWithObjects:@"120", @"80", @"6.6", @"4.4", kGlucoseUnits_mgdL, a, nil];
	NSDictionary* d = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	[[NSUserDefaults standardUserDefaults] registerDefaults:d];

	categories = [[NSMutableArray alloc] init];
	defaultInsulinTypes = [[NSMutableArray alloc] init];
	insulinTypes = [[NSMutableArray alloc] init];

	if( !shortDateFormatter )
	{
		shortDateFormatter = [[NSDateFormatter alloc] init];
		[shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
	}

    logViewController = [[LogViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController* aNavigationController = [[UINavigationController alloc] initWithRootViewController:logViewController];
    self.navController = aNavigationController;
	navController.navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLogEntry:)];
/*
	UIButton* b = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[b addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem* bb = [[UIBarButtonItem alloc] initWithCustomView:b];
//	bb.target = self;
//	bb.action = @selector(showSettings:);
	navController.navigationBar.topItem.leftBarButtonItem = bb;
//	navController.navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)];
*/	
    [aNavigationController release];
    [logViewController release];

    // The application ships with a default database in its bundle. If anything in the application
    // bundle is altered, the code sign will fail. We want the database to be editable by users, 
    // so we need to create a copy of it in the application's Documents directory.     
    [self createEditableCopyOfDatabaseIfNeeded];
	[self openLogDatabase];
	
	// Call these in this order
    [self loadCategories];
    [self loadInsulinTypes];
	[self loadDefaultInsulinTypes];	// Must be after loadInsulinTypes
	sections = [LogDay loadAllSections:database];

	// Configure and display the window
    [window addSubview:[navController view]];
    [window makeKeyAndVisible];
}

- (void)dealloc
{
	[categoryViewController release];
	[defaultInsulinTypes release];
	[categories release];
	[insulinTypes release];
	[sections release];
//	[shortDateFormatter release];
	[window release];
	[super dealloc];
}

// Save all changes to the database, then close it.
- (void)applicationWillTerminate:(UIApplication *)application
{
	// Flush all entries
	for(NSMutableDictionary* s in self.sections)
	{
		for(LogEntry* e in [s objectForKey:@"LogEntries"])
		{
			[e flush:database];
		}
	}
    [LogEntry finalizeStatements];
    [self closeLogDatabase];	// Close the database.
}

#pragma mark -
#pragma mark Database Initialization

// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded
{
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:LOG_SQL];
    if( [fileManager fileExistsAtPath:writableDBPath] )
		return;

	NSLog(@"Database did not exist\n");
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:LOG_SQL];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}

- (BOOL) openLogDatabase
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:LOG_SQL];
    // Open the database. The database was prepared outside the application.
    if( sqlite3_open([path UTF8String], &database) != SQLITE_OK )
	{
        sqlite3_close(database);	// Cleanup after failure (release resources)
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
		return NO;
	}
	return YES;		
}

- (void) closeLogDatabase
{
	sqlite3_close(database);
}

- (void) loadCategories
{
	const char *query = "SELECT categoryID, sequence, name FROM LogEntryCategories ORDER BY sequence";
	sqlite3_stmt *statement;

	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			int categoryID = sqlite3_column_int(statement, 0);
			const unsigned char *const s = sqlite3_column_text(statement, 2);
			NSString* name = s ? [NSString stringWithUTF8String:(const char*)s] : @"";
			[self.categories addObject:[[Category alloc] initWithID:categoryID name:name]];
		}
		sqlite3_finalize(statement);
	}
	// Find the max width of the categoryName strings so it can be used for layout
	[self updateCategoryNameMaxWidth];
}

- (void) loadDefaultInsulinTypes
{
	if( ![self.insulinTypes count] )
		return;

	NSArray* a = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultInsulinTypes"];
	for( NSNumber* typeID in a )
		[self.defaultInsulinTypes addObject:[self findInsulinTypeForID:[typeID intValue]]];
}

- (void) loadInsulinTypes
{
	const char *const query = "SELECT typeID, sequence, shortName FROM InsulinTypes ORDER BY sequence";
	sqlite3_stmt *statement;

	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			int typeID = sqlite3_column_int(statement, 0);
			const unsigned char *const s = sqlite3_column_text(statement, 2);
			NSString* shortName = s ? [NSString stringWithUTF8String:(const char*)s] : nil;
			[self.insulinTypes addObject:[[InsulinType alloc] initWithID:typeID name:shortName]];
		}
		sqlite3_finalize(statement);
	}
	// Find the max width of the shortName strings so it can be used for layout
	[self updateInsulinTypeShortNameMaxWidth];
}
/*
// Return the number of days worth of log entries in the database
- (unsigned) getNumDays
{
	const char *query = "SELECT COUNT(*) FROM localLogEntries GROUP BY date(timestamp)";
	sqlite3_stmt *statement;
	unsigned numDays = 0;

	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		while( sqlite3_step(statement) == SQLITE_ROW )
			++numDays;
//			numDays = sqlite3_column_int(statement, 0);
		sqlite3_finalize(statement);
	}
	return numDays;
}

- (NSArray*) getDays
{
	const char *query = "SELECT timestamp, COUNT(timestamp) FROM localLogEntries GROUP BY date(timestamp,'unixepoch')";
	sqlite3_stmt *statement;
	NSMutableArray* days = [[NSMutableArray alloc] init];
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			[days addObject:[NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(statement, 0)]];
			NSLog(@"found day %s\n", sqlite3_column_text(statement, 0));
		}
		sqlite3_finalize(statement);
	}
	return days;
}
*/

#pragma mark -
#pragma mark Array Management

// Delete a LogEntry from memory and the database
// This function is only called from commitEditingStyle:
// Returns YES if the entry's section became empty and was deleted
- (BOOL) deleteLogEntryAtIndexPath:(NSIndexPath*)indexPath
{
	LogDay *const s = [sections objectAtIndex:indexPath.section];
	LogEntry *const entry = [s.entries objectAtIndex:indexPath.row];
	[entry deleteFromDatabase:database];
	return [self deleteLogEntry:entry fromSection:s];
}

// Returns YES if the entry's section became empty and was deleted
- (BOOL) deleteLogEntry:(LogEntry*)entry fromSection:(LogDay*)section
{
	[section removeEntry:entry];

	if( 0 == [section.entries count] )	// Delete the section if it's now empty
	{
		NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[sections indexOfObjectIdenticalTo:section]];
		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"sections"];
		[self.sections removeObjectIdenticalTo:section];
		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"sections"];
		
		return YES;
	}
	return NO;
}

- (BOOL) deleteLogEntryIndex:(unsigned)entryIndex fromSectionIndex:(unsigned)sectionIndex
{
	LogDay *const s = [sections objectAtIndex:sectionIndex];
	return [self deleteLogEntry:[s.entries objectAtIndex:entryIndex] fromSection:s];
}

- (Category*) findCategoryForID:(unsigned)categoryID
{
	for( Category* c in categories )
		if( c.categoryID == categoryID )
			return c;
	return nil;
}

- (InsulinType*) findInsulinTypeForID:(unsigned)typeID
{
	for( InsulinType* t in insulinTypes )
		if( t.typeID == typeID )
			return t;
	return nil;
}

- (LogDay*) findSectionForDate:(NSDate*)d
{
	NSCalendar *const calendar = [NSCalendar currentCalendar];
	static const unsigned components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *const date = [calendar components:components fromDate:d];
//	NSDate* today = [NSDate date];
//	NSMutableDictionary* r = nil;
	for( LogDay* s in sections )
	{
		NSDateComponents *const c = [calendar components:components fromDate:s.date];
//		NSDateComponents* c = [calendar components:components fromDate:s.date toDate:today options:0];
		if( (date.day == c.day) && (date.month == c.month) && (date.year == c.year) )
			return s;
	}
	return nil;
}

- (LogDay*) getSectionForDate:(NSDate*)date
{
	LogDay* s = [self findSectionForDate:date];
	if( s )
		return s;

	s = [[LogDay alloc] initWithDate:date];
	s.name = [shortDateFormatter stringFromDate:date];

	// At this point it's already known that the given date doesn't match 
	//	anything in the array. So, only need to compare seconds; no need to 
	//	create calendar components.
	unsigned i = 0;
	if( [sections count] )
	{
		// Find the index that entry should be inserted at
		const double a = [date timeIntervalSince1970];
		for( LogDay* s in sections )
		{
			if( a > [s.date timeIntervalSince1970] )
				break;
			++i;
		}
	}
	
	NSIndexSet *const indexSet = [NSIndexSet indexSetWithIndex:i];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"sections"];
	[sections insertObject:s atIndex:i];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"sections"];

	return s;
}

/*
int compareLogEntriesByDate(id left, id right, void* context)
{
	return [((LogEntry*)left).timestamp compare:((LogEntry*)right).timestamp];
}
*/

#pragma mark -
#pragma mark Record Management

// Create a new log entry in response to a button press
//  Always creates with current date and time, and therefore prepends
- (void) addLogEntry:(id)sender
{
	NSLog(@"addLogEntry");

	// Create a new record in the database and get its automatically generated primary key.
    unsigned entryID = [LogEntry insertNewLogEntryIntoDatabase:database];
	LogEntry* newEntry = [[LogEntry alloc] initWithID:entryID database:database];
//	LogEntry* newEntry = [[LogEntry alloc] initWithTimestamp:[NSDate date]];

	// Set defaults for the new LogEntry
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	// Don't use the returned string directly because glucoseUnits is used elsewhere
	//	in pointer comparisons for performance reasons. Consequently, it must be 
	//	a pointer to one of the constants in Constants.h.
	if( [[defaults objectForKey:kDefaultGlucoseUnits] isEqualToString:kGlucoseUnits_mgdL] )
		newEntry.glucoseUnits = kGlucoseUnits_mgdL;
	else
		newEntry.glucoseUnits = kGlucoseUnits_mmolL;

	// Find the proper section for the new LogEntry
	unsigned sectionIndex = 0;
	LogDay *const s = [self getSectionForDate:newEntry.timestamp];
	sectionIndex = [sections indexOfObjectIdenticalTo:s];

	// Create an index set to use in fine grained KVO notifications
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];

	// Insert and post notifications of changes
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"entries"];
	[s insertEntry:newEntry atIndex:0];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"entries"];
//	[newEntry release];
//	[navController.topViewController inspectLogEntry:newEntry];
//	[[navController.topViewController tableView] reloadData];

}

- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to
{
	const char *query = "DELETE FROM localLogEntries WHERE date(timestamp,'unixepoch','localtime') >= date(?,'unixepoch','localtime') AND date(timestamp,'unixepoch','localtime') <= date(?,'unixepoch','localtime')";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, [from timeIntervalSince1970]);
		sqlite3_bind_int(statement, 2, [to timeIntervalSince1970]);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));

		// Delete the corresponding sections
		NSMutableArray* a = [[NSMutableArray alloc] init];
		for( NSMutableDictionary* s in sections )
		{
			NSDate *const d = [s objectForKey:@"SectionDate"];
			NSComparisonResult b = [from compare:d];
			NSComparisonResult c = [to compare:d];
			
			if( ((b == NSOrderedAscending) || (b == NSOrderedSame)) && 
			    ((c == NSOrderedDescending) || (c == NSOrderedSame)) )
				[a addObject:s];
		}
		for( NSMutableDictionary* s in a )
		{
			NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[sections indexOfObjectIdenticalTo:s]];
			[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"sections"];
			[sections removeObjectIdenticalTo:s];
			[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"sections"];
		}
	}
}

- (NSDate*) earliestLogEntryDate
{
	if( ![self numLogEntries] )
		return nil;
	
	const char* q = "SELECT MIN(timestamp) from localLogEntries";
	sqlite3_stmt *statement;
	NSDate* d = nil;
	
	if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) == SQLITE_OK )
	{
		unsigned i = 0;
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			NSAssert(i==0, @"Too many rows returned for MIN()");
			d = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(statement, 0)];
			++i;
		}
		sqlite3_finalize(statement);
	}
	return d;
}

- (unsigned) numLogEntries
{
	const char* q = "SELECT COUNT() from localLogEntries";
	sqlite3_stmt *statement;
	unsigned num = 0;
	
	if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) == SQLITE_OK )
	{
		unsigned i = 0;
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			NSAssert(i==0, @"Too many rows returned for COUNT()");
			num = sqlite3_column_int(statement, 0);
			++i;
		}
		sqlite3_finalize(statement);
	}
	return num;
}

- (unsigned) numLogEntriesFrom:(NSDate*)from to:(NSDate*)to
{
	const char* q = "SELECT COUNT() from localLogEntries WHERE date(timestamp,'unixepoch','localtime') >= date(?,'unixepoch','localtime') AND date(timestamp,'unixepoch','localtime') <= date(?,'unixepoch','localtime')";
	sqlite3_stmt *statement;
	unsigned num = 0;
	
	if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, [from timeIntervalSince1970]);
		sqlite3_bind_int(statement, 2, [to timeIntervalSince1970]);
		unsigned i = 0;
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			NSAssert(i==0, @"Too many rows returned for COUNT() in numLogEntriesFrom:to:");
			num = sqlite3_column_int(statement, 0);
			++i;
		}
		sqlite3_finalize(statement);
	}
	return num;
}

- (unsigned) numRowsForCategoryID:(NSInteger)catID
{
	return 0;
}

#pragma mark Category Records

- (void) deleteEntriesForCategoryID:(unsigned)categoryID
{
	const char *query = "DELETE FROM localLogEntries WHERE categoryID=?";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, categoryID);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
}

- (void) deleteCategoryID:(unsigned)categoryID
{
	const char *query = "DELETE FROM LogEntryCategories WHERE categoryID=?";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, categoryID);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
}

// Create a new Category record and add it to the categories array
- (void) addCategory:(NSString*)name
{
	[categories addObject:[Category insertNewCategoryIntoDatabase:database withName:name]];
}

- (void) updateCategory:(Category*)c
{
	static char *sql = "UPDATE LogEntryCategories SET name=? WHERE categoryID=?";
	sqlite3_stmt *statement;
	if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
	
	for( Category* c in categories )
	{
		sqlite3_bind_text(statement, 1, [c.categoryName UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(statement, 2, c.categoryID);
		int success = sqlite3_step(statement);
		sqlite3_reset(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
	}
	sqlite3_finalize(statement);
}

// Flush the category list to the database
//  !! This truncates the table first, then writes the entire array !!
- (void) flushCategories
{
	// Truncate the category table
	sqlite3_exec(database, "DELETE FROM LogEntryCategories", NULL, NULL, NULL);
	
	static char *sql = "INSERT INTO LogEntryCategories (categoryID, sequence, name) VALUES(?,?,?)";
	sqlite3_stmt *statement;
	if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));

	unsigned i = 0;
	for( Category* c in categories )
	{
		sqlite3_bind_int(statement, 1, c.categoryID);
		sqlite3_bind_int(statement, 2, i);
		sqlite3_bind_text(statement, 3, [c.categoryName UTF8String], -1, SQLITE_TRANSIENT);
		int success = sqlite3_step(statement);
		sqlite3_reset(statement);		// Reset the query for the next use
		sqlite3_clear_bindings(statement);	//Clear all bindings for next time
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
		++i;
	}
	sqlite3_finalize(statement);
}

- (void) updateCategoryNameMaxWidth
{
	float maxWidth = 0;
	for( Category* c in categories )
	{
		const float a = [c.categoryName sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]].width;
		if( a > maxWidth )
			maxWidth = a;
	}
	maxCategoryNameWidth = maxWidth;
}

#pragma mark InsulinType Records

// Create a new Category record and add it to the categories array
- (void) addInsulinType:(NSString*)name
{
	[insulinTypes addObject:[InsulinType insertNewInsulinTypeIntoDatabase:database withName:name]];
}

- (void) deleteEntriesForInsulinTypeID:(unsigned)typeID
{
	const char *query = "DELETE FROM InsulinTypes WHERE typeID=?";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, typeID);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
}

- (void) deleteInsulinTypeID:(unsigned)typeID
{
	const char *query = "DELETE FROM InsulinTypes WHERE typeID=?";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, typeID);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
}

// Flush the insulin types list to the database
//  !! This truncates the table first, then writes the entire array !!
- (void) flushInsulinTypes
{
	// Truncate the category table
	sqlite3_exec(database, "DELETE FROM InsulinTypes", NULL, NULL, NULL);
	
	static char *sql = "INSERT INTO InsulinTypes (typeID, sequence, shortName) VALUES(?,?,?)";
	sqlite3_stmt *statement;
	if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
	
	unsigned i = 0;
	for( InsulinType* type in insulinTypes )
	{
		sqlite3_bind_int(statement, 1, type.typeID);
		sqlite3_bind_int(statement, 2, i);
		sqlite3_bind_text(statement, 3, [type.shortName UTF8String], -1, SQLITE_TRANSIENT);
		int success = sqlite3_step(statement);
		sqlite3_reset(statement);		// Reset the query for the next use
		sqlite3_clear_bindings(statement);	//Clear all bindings for next time
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
		++i;
	}
	sqlite3_finalize(statement);
}

// Flush the insulin types list to the database
//  !! This truncates the table first, then writes the entire array !!
- (void) flushDefaultInsulinTypes
{
	NSMutableArray* a = [NSMutableArray arrayWithCapacity:[defaultInsulinTypes count]];
	for( InsulinType* type in defaultInsulinTypes )
		[a addObject:[NSNumber numberWithInt:type.typeID]];
	[[NSUserDefaults standardUserDefaults] setObject:a forKey:kDefaultInsulinTypes];
}

- (void) updateInsulinType:(InsulinType*)type
{
	static char *sql = "UPDATE InsulinTypes SET shortName=? WHERE typeID=?";
	sqlite3_stmt *statement;
	if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
	
	for( InsulinType* type in insulinTypes )
	{
		sqlite3_bind_text(statement, 1, [type.shortName UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_int(statement, 2, type.typeID);
		int success = sqlite3_step(statement);
		sqlite3_reset(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
	}
	sqlite3_finalize(statement);
}

- (void) updateInsulinTypeShortNameMaxWidth
{
	float maxWidth = 0;
	for( InsulinType* t in insulinTypes )
	{
		const float a = [t.shortName sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]].width;
		if( a > maxWidth )
			maxWidth = a;
	}
	maxInsulinTypeShortNameWidth = maxWidth;
}

#pragma mark -
#pragma mark GData Interface

- (GDataServiceGoogleDocs *)docService
{
	static GDataServiceGoogleDocs*	service = nil;
	if( !service )
	{
		service = [[GDataServiceGoogleDocs alloc] init];
		
		[service setUserAgent:@"net.bfoz-Glucose-0.1"];
	}
	return service;
}

- (void) setUserCredentialsWithUsername:(NSString*)user password:(NSString*)pass
{
	[self.docService setUserCredentialsWithUsername:user password:pass];
}

#pragma mark -
#pragma mark Properties

- (CategoryViewController*) categoryViewController
{
	if( !categoryViewController )
		categoryViewController = [[CategoryViewController alloc] initWithStyle:UITableViewStylePlain];
	return categoryViewController;
}

- (InsulinTypeViewController*) insulinTypeViewController
{
	if( !insulinTypeViewController )
		insulinTypeViewController = [[InsulinTypeViewController alloc] initWithStyle:UITableViewStylePlain];
	return insulinTypeViewController;
}

@end
