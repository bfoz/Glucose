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
#import	"GlucoseWindow.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogEntry.h"
#import "LogDay.h"
#import "CategoryViewController.h"
#import "InsulinTypeViewController.h"
#import "LogViewController.h"

#import "GDataDocs.h"

#define	LOG_SQL		@"glucose.sqlite"

AppDelegate* appDelegate = nil;

@interface AppDelegate ()

@property (nonatomic, readonly)	NSMutableArray*		sections;

- (void) createEditableCopyOfDatabaseIfNeeded;
- (void) closeLogDatabase;

- (void) loadDefaultInsulinTypes;
- (void) loadInsulinTypes:(NSMutableArray*)types fromDB:(sqlite3*)db;
- (void) loadAllSections;
@end

@implementation AppDelegate

@synthesize window;
@synthesize navController;
@synthesize categories, defaultInsulinTypes, insulinTypes;
@synthesize logViewController;
@synthesize sections;

NSDateFormatter* shortDateFormatter = nil;

unsigned maxCategoryNameWidth = 0;
unsigned maxInsulinTypeShortNameWidth = 0;

#pragma mark -
#pragma mark <UIApplicationDelegate>

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{	
    // Create the top level window (instead of using a default nib)
    // Use a subclass of UIWindow for capturing shake events
    window = [[GlucoseWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Initialize the global application delegate pointer
    appDelegate = self;

	// Set the background color for the flip animation going to/from the settings view
	//  The background color is what shows up behind the flipping views
	window.backgroundColor = [UIColor blackColor];
	
	// Register default defaults
	NSArray* a = [NSArray arrayWithObjects:[NSNumber numberWithInt:6], [NSNumber numberWithInt:1], nil];	// NPH, Aspart
	NSArray* keys = [NSArray arrayWithObjects:kHighGlucoseWarning0, kLowGlucoseWarning0, kHighGlucoseWarning1, kLowGlucoseWarning1, kDefaultGlucoseUnits, kDefaultInsulinPrecision, kDefaultInsulinTypes, kExportGoogleShareEnable, nil];
	NSArray* values = [NSArray arrayWithObjects:@"120", @"80", @"6.6", @"4.4", kGlucoseUnits_mgdL, [NSNumber numberWithInt:0], a, @"NO", nil];
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
    logViewController.delegate = self;
    UINavigationController* aNavigationController = [[UINavigationController alloc] initWithRootViewController:logViewController];
    self.navController = aNavigationController;
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

    // Try to open the log database
    if( ![self database] )
    {
	NSLog(@"Could not open log database");
	return NO;
    }
	
	// Call these in this order
    [Category loadCategories:self.categories fromDatabase:database];
    [InsulinType loadInsulinTypes:self.insulinTypes fromDatabase:database];
	[self loadDefaultInsulinTypes];	// Must be after loadInsulinTypes
    // Load the most recent 30 days
    sections = [[NSMutableArray alloc] init];
    numberOfSections = [LogDay numberOfDays:database];
    [LogDay loadDays:sections fromDatabase:database limit:30 offset:0];

    // Find the max width of the categoryName strings so it can be used for layout
    [self updateCategoryNameMaxWidth];
    // Find the max width of the InsulinType shortName strings so it can be used for layout
    [self updateInsulinTypeShortNameMaxWidth];

    // Create an empty "Today" object if no LogDays were loaded
    if( 0 == [sections count] )
    {
	NSDate *const day = [NSDate date];
	LogDay *const section = [[LogDay alloc] initWithDate:day];
	section.name = [shortDateFormatter stringFromDate:day];
	[sections addObject:section];
	[section release];
    }

	// Configure and display the window
    [window addSubview:[navController view]];
    [window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self flushLogEntries];	// Flush all entries
    [LogEntry finalizeStatements];
    [self closeLogDatabase];	// Close the database.
}

- (void)dealloc
{
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
    [self flushLogEntries];	// Flush all entries
    [LogEntry finalizeStatements];
    [self closeLogDatabase];	// Close the database.
}

#pragma mark -
#pragma mark <LogViewDelegate>

- (BOOL) canLoadMoreDays
{
    return numberOfSections > [self.sections count];
}

- (void) didPressNewLogEntry
{
    // Create a new record in the database and get its automatically generated primary key.
    const unsigned entryID = [LogEntry insertNewLogEntryIntoDatabase:self.database];
    LogEntry* entry = [[LogEntry alloc] initWithID:entryID database:self.database];

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

    // Display the detail view so the user can edit the new entry
    [logViewController inspectNewLogEntry:entry];
}

- (LogDay*) logDayAtIndex:(unsigned)index
{
    return [sections objectAtIndex:index];
}

- (LogEntry*) logEntryAtIndex:(unsigned)entry inDayIndex:(unsigned)day
{
    LogDay *const d = [self logDayAtIndex:day];
    if( d && d.count && ![d.entries count] )
	[d hydrate:database];
    return (entry >= [d.entries count]) ? nil : [d.entries objectAtIndex:entry];
}

- (unsigned) numberOfLogDays
{
    return numberOfSections;
}

- (void) didSelectLoadMore
{
    [LogDay loadDays:self.sections fromDatabase:self.database limit:30 offset:[self.sections count]];
}

// Delete a LogEntry from memory and the database
- (void) logViewDidDeleteLogEntryAtRow:(unsigned)row inSection:(unsigned)section;
{
    LogDay *const s = [sections objectAtIndex:section];
    LogEntry *const entry = [s.entries objectAtIndex:row];
    [entry deleteFromDatabase:self.database];
    [self deleteLogEntry:entry fromSection:s];
}

- (void) logViewDidDeleteSectionAtIndex:(unsigned)section;
{
    // Delete all of the LogDay's entries from the database
    LogDay *const s = [sections objectAtIndex:section];
    [s deleteAllEntriesFromDatabase:self.database];

    // Remove the LogDay itself
    [self.sections removeObjectAtIndex:section];
}

- (void) logViewDidMoveLogEntry:(LogEntry*)entry fromSection:(LogDay*)from toSection:(LogDay*)to
{
    [to insertEntry:entry];			    // Add entry to new section
    [self deleteLogEntry:entry fromSection:from];   // Remove from old section
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

sqlite3* openBundledDatabase()
{
    sqlite3*	db;

    // Open the default databse from the main bundle
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:LOG_SQL];
    if( sqlite3_open([defaultDBPath UTF8String], &db) != SQLITE_OK )
    {
	sqlite3_close(db);	// Cleanup after failure (release resources)
	NSLog(@"Failed to open database with message '%s'.", sqlite3_errmsg(db));
	return NULL;
    }
    return db;
}

- (void) closeLogDatabase
{
	sqlite3_close(database);
    database = nil;
}

- (void) loadDefaultInsulinTypes
{
	if( ![self.insulinTypes count] )
		return;

	NSArray* a = [[NSUserDefaults standardUserDefaults] objectForKey:@"DefaultInsulinTypes"];
	for( NSNumber* typeID in a )
	{
		InsulinType* t = [self findInsulinTypeForID:[typeID intValue]];
		if( t )
			[self.defaultInsulinTypes addObject:t];
	}
}

// Add the categories from the bundled defaults database
- (void) appendBundledCategories
{
    sqlite3* db = openBundledDatabase();
    if( !db )
	return;

    // Load the default categories
    NSMutableArray* a = [NSMutableArray arrayWithCapacity:1];
    [Category loadCategories:a fromDatabase:db];

    sqlite3_close(db);	    // Close the database

    // Loop through the items to add
    for( Category* c in a )
    {
	// See if the category already exists
	if( ![self findCategoryForID:c.categoryID] )
	{
	    [Category insertCategory:c intoDatabase:database];
	    [categories addObject:c];
	}
    }

    // Find the max width of the categoryName strings so it can be used for layout
    [self updateCategoryNameMaxWidth];
}

- (void) appendBundledInsulinTypes
{
    sqlite3* db = openBundledDatabase();
    if( !db )
	return;

    // Load the default insulin types
    NSMutableArray* a = [NSMutableArray arrayWithCapacity:1];
    [InsulinType loadInsulinTypes:a fromDatabase:db];

    sqlite3_close(db);	    // Close the database

    // Loop through the items to add
    for( InsulinType* t in a )
    {
	// See if the category already exists
	if( ![self findInsulinTypeForID:t.typeID] )
	{
	    [InsulinType insertInsulinType:t intoDatabase:database];
	    [insulinTypes addObject:t];
	}
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

- (void) deleteLogEntry:(LogEntry*)entry fromSection:(LogDay*)section
{
	[section removeEntry:entry];

    if( 0 == [section.entries count] )
		[self.sections removeObjectIdenticalTo:section];
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
	
	[sections insertObject:s atIndex:i];
    [s release];
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
		for( LogDay* s in sections )
		{
			NSDate *const d = s.date;
			NSComparisonResult b = [from compare:d];
			NSComparisonResult c = [to compare:d];
			
			if( ((b == NSOrderedAscending) || (b == NSOrderedSame)) && 
			    ((c == NSOrderedDescending) || (c == NSOrderedSame)) )
				[a addObject:s];
		}
		for( LogDay* s in a )
			[sections removeObjectIdenticalTo:s];
	[a release];
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

- (void) flushLogEntries
{
    for( LogDay* s in self.sections )
	for( LogEntry* e in s.entries )
	    [e flush:database];
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

- (unsigned) numLogEntriesForInsulinTypeID:(unsigned)typeID
{
    return [LogEntry numLogEntriesForInsulinTypeID:typeID database:database];
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

- (unsigned) numRowsForCategoryID:(unsigned)catID
{
    return [LogEntry numLogEntriesForCategoryID:catID database:database];
}

#pragma mark Category Records

// Create a new Category record and add it to the categories array
- (void) addCategory:(NSString*)name
{
    Category* c = [Category newCategoryWithName:name database:database];
    [categories addObject:c];
    [c release];
}

// Purge a Category record from the database and the category array
- (void) purgeCategoryAtIndex:(unsigned)index
{
	Category *const category = [categories objectAtIndex:index];

    // Move all LogEntries in the deleted category to category "None"
	NSArray* a = [NSArray arrayWithArray:sections];
	for( LogDay* s in a )
	{
		NSArray* entries = [NSArray arrayWithArray:s.entries];
		for( LogEntry* e in entries )
			if( e.category && (e.category == category) )
			    e.category = nil;;
	}

    [LogEntry moveAllEntriesInCategory:category toCategory:nil database:database];
    [Category deleteCategory:category fromDatabase:database];
    [self removeCategoryAtIndex:index];
}

// Remove an Category record and generate a KV notification
- (void) removeCategoryAtIndex:(unsigned)index
{
	[categories removeObjectAtIndex:index];
}

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

- (void) updateCategory:(Category*)c
{
    [c flush:database];
    [self updateCategoryNameMaxWidth];
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

// Create a new InsulinType record and add it to the insulinTypes array
- (void) addInsulinType:(NSString*)name
{
    InsulinType* insulin = [InsulinType newInsulinTypeWithName:name database:database];
    [insulinTypes addObject:insulin];
    [insulin release];
}

// Purge an InsulinType record from the database and the insulinTypes array
- (void) purgeInsulinTypeAtIndex:(unsigned)index
{
	InsulinType *const type = [insulinTypes objectAtIndex:index];
	const unsigned typeID = [type typeID];
	[LogEntry deleteDosesForInsulinTypeID:typeID fromDatabase:database];
	[type deleteFromDatabase:database];
    [self removeDefaultInsulinType:type];   // Must be before deleting the InsulinType
	[self removeInsulinTypeAtIndex:index];

	// Remove all of the LogEntry doses with the deleted insulin type
	for( LogDay* s in sections )
	{
		for( LogEntry* e in s.entries )
		{
			NSArray* doses = [NSArray arrayWithArray:e.insulin];
			for( InsulinDose* d in doses )
				if( d.type && (d.type == type) )
					[e.insulin removeObjectIdenticalTo:d];
		}
	}
}

- (void) removeDefaultInsulinType:(InsulinType*)type
{
	[self.defaultInsulinTypes removeObjectIdenticalTo:type];
	[self flushDefaultInsulinTypes];
}

// Remove an InsulinType record and generate a KV notification
- (void) removeInsulinTypeAtIndex:(unsigned)index
{
	[insulinTypes removeObjectAtIndex:index];
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
    [type flush:database];
    [self updateInsulinTypeShortNameMaxWidth];
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

- (sqlite3*) database
{
    if( !database )
    {
	NSArray *const paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *const documentsDirectory = [paths objectAtIndex:0];
	NSString *const path = [documentsDirectory stringByAppendingPathComponent:LOG_SQL];
	// Open the database. The database was prepared outside the application.
	if( sqlite3_open([path UTF8String], &database) != SQLITE_OK )
	{
	    // sqlite3_open() doesn't always return a valid connection object on failure
	    if( database )
	    {
		sqlite3_close(database);	// Cleanup after failure (release resources)
		NSLog(@"Failed to open database with message '%s'.", sqlite3_errmsg(database));
		database = NULL;
	    }
	    else
		NSLog(@"Failed to allocate a database object");

	    return NULL;
	}
    }

    return database;
}

// This is a dummy property to get KVO to work on the dummy entries key
- (NSMutableArray*)entries
{
	return nil;
}

@end
