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
#import "LogModel.h"
#import "LogViewController.h"

#import "GDataDocs.h"

#define	LOG_SQL		@"glucose.sqlite"

AppDelegate* appDelegate = nil;

@interface AppDelegate ()

- (void) createEditableCopyOfDatabaseIfNeeded;

- (void) loadAllSections;
@end

@implementation AppDelegate

@synthesize window;
@synthesize navController;
@synthesize logViewController;

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

	if( !shortDateFormatter )
	{
		shortDateFormatter = [[NSDateFormatter alloc] init];
		[shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
	}

    // Create the Log Model object
    model = [[LogModel alloc] init];
    if( !model )
    {
	NSLog(@"Could not create a LogModel");
	return NO;
    }

    logViewController = [[LogViewController alloc] initWithStyle:UITableViewStylePlain];
    logViewController.delegate = self;
    logViewController.model = model;
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
    if( ![model database] )
    {
	NSLog(@"Could not open log database");
	return NO;
    }

    // Find the max width of the categoryName strings so it can be used for layout
    [self updateCategoryNameMaxWidth];
    // Find the max width of the InsulinType shortName strings so it can be used for layout
    [self updateInsulinTypeShortNameMaxWidth];

    // Create an empty "Today" object if no LogDays are available
    if( 0 == [model numberOfLogDays] )
    {
	NSDate *const day = [NSDate date];
	LogDay *const section = [[LogDay alloc] initWithDate:day];
	section.name = [shortDateFormatter stringFromDate:day];
	[model.days addObject:section];
	[section release];
    }

	// Configure and display the window
    [window addSubview:[navController view]];
    [window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [model flush];	// Flush all entries
    [model close];	// Close all open databases
}

- (void)dealloc
{
	[window release];
	[super dealloc];
}

// Save all changes to the database, then close it.
- (void)applicationWillTerminate:(UIApplication *)application
{
    [model flush];	// Flush all entries
    [model close];	// Close all open databases
}

#pragma mark -
#pragma mark <LogViewDelegate>

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
	if( ![model categoryForCategoryID:c.categoryID] )
	{
	    [Category insertCategory:c intoDatabase:model.database];
	    [model.categories addObject:c];
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
	if( ![model insulinTypeForInsulinTypeID:t.typeID] )
	{
	    [InsulinType insertInsulinType:t intoDatabase:model.database];
	    [model.insulinTypes addObject:t];
	}
    }

    // Find the max width of the shortName strings so it can be used for layout
    [self updateInsulinTypeShortNameMaxWidth];
}

#pragma mark -
#pragma mark Array Management

- (LogDay*) findSectionForDate:(NSDate*)d
{
	NSCalendar *const calendar = [NSCalendar currentCalendar];
	static const unsigned components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *const date = [calendar components:components fromDate:d];
//	NSDate* today = [NSDate date];
//	NSMutableDictionary* r = nil;
	for( LogDay* s in model.days )
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
	if( model.numberOfLoadedLogDays )
	{
		// Find the index that entry should be inserted at
		const double a = [date timeIntervalSince1970];
		for( LogDay* s in model.days )
		{
			if( a > [s.date timeIntervalSince1970] )
				break;
			++i;
		}
	}

    [model.days insertObject:s atIndex:i];
    [s release];
	return s;
}

#pragma mark -
#pragma mark Record Management

- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to
{
	const char *query = "DELETE FROM localLogEntries WHERE date(timestamp,'unixepoch','localtime') >= date(?,'unixepoch','localtime') AND date(timestamp,'unixepoch','localtime') <= date(?,'unixepoch','localtime')";
	sqlite3_stmt *statement;

	if( sqlite3_prepare_v2(model.database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, [from timeIntervalSince1970]);
		sqlite3_bind_int(statement, 2, [to timeIntervalSince1970]);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(model.database));

		// Delete the corresponding sections
		NSMutableArray* a = [[NSMutableArray alloc] init];
		for( LogDay* s in model.days )
		{
			NSDate *const d = s.date;
			NSComparisonResult b = [from compare:d];
			NSComparisonResult c = [to compare:d];
			
			if( ((b == NSOrderedAscending) || (b == NSOrderedSame)) && 
			    ((c == NSOrderedDescending) || (c == NSOrderedSame)) )
				[a addObject:s];
		}
		for( LogDay* s in a )
			[model.days removeObjectIdenticalTo:s];
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

	if( sqlite3_prepare_v2(model.database, q, -1, &statement, NULL) == SQLITE_OK )
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

	if( sqlite3_prepare_v2(model.database, q, -1, &statement, NULL) == SQLITE_OK )
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
    return [LogEntry numLogEntriesForInsulinTypeID:typeID database:model.database];
}

- (unsigned) numLogEntriesFrom:(NSDate*)from to:(NSDate*)to
{
	const char* q = "SELECT COUNT() from localLogEntries WHERE date(timestamp,'unixepoch','localtime') >= date(?,'unixepoch','localtime') AND date(timestamp,'unixepoch','localtime') <= date(?,'unixepoch','localtime')";
	sqlite3_stmt *statement;
	unsigned num = 0;

	if( sqlite3_prepare_v2(model.database, q, -1, &statement, NULL) == SQLITE_OK )
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
    return [LogEntry numLogEntriesForCategoryID:catID database:model.database];
}

#pragma mark Category Records

// Create a new Category record and add it to the categories array
- (void) addCategory:(NSString*)name
{
    Category* c = [Category newCategoryWithName:name database:model.database];
    [model.categories addObject:c];
    [c release];
}

// Purge a Category record from the database and the category array
- (void) purgeCategoryAtIndex:(unsigned)index
{
    Category *const category = [model.categories objectAtIndex:index];

    // Move all LogEntries in the deleted category to category "None"
	NSArray* a = [NSArray arrayWithArray:model.days];
	for( LogDay* s in a )
	{
		NSArray* entries = [NSArray arrayWithArray:s.entries];
		for( LogEntry* e in entries )
			if( e.category && (e.category == category) )
			    e.category = nil;;
	}

    [LogEntry moveAllEntriesInCategory:category toCategory:nil database:model.database];
    [Category deleteCategory:category fromDatabase:model.database];
    [self removeCategoryAtIndex:index];
}

// Remove an Category record and generate a KV notification
- (void) removeCategoryAtIndex:(unsigned)index
{
    [model.categories removeObjectAtIndex:index];
}

- (void) deleteEntriesForCategoryID:(unsigned)categoryID
{
	const char *query = "DELETE FROM localLogEntries WHERE categoryID=?";
	sqlite3_stmt *statement;

	if( sqlite3_prepare_v2(model.database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, categoryID);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(model.database));
	}
}

- (void) updateCategory:(Category*)c
{
    [c flush:model.database];
    [self updateCategoryNameMaxWidth];
}

// Flush the category list to the database
//  !! This truncates the table first, then writes the entire array !!
- (void) flushCategories
{
	// Truncate the category table
	sqlite3_exec(model.database, "DELETE FROM LogEntryCategories", NULL, NULL, NULL);

	static char *sql = "INSERT INTO LogEntryCategories (categoryID, sequence, name) VALUES(?,?,?)";
	sqlite3_stmt *statement;
	if( sqlite3_prepare_v2(model.database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(model.database));

	unsigned i = 0;
	for( Category* c in model.categories )
	{
		sqlite3_bind_int(statement, 1, c.categoryID);
		sqlite3_bind_int(statement, 2, i);
		sqlite3_bind_text(statement, 3, [c.categoryName UTF8String], -1, SQLITE_TRANSIENT);
		int success = sqlite3_step(statement);
		sqlite3_reset(statement);		// Reset the query for the next use
		sqlite3_clear_bindings(statement);	//Clear all bindings for next time
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(model.database));
		++i;
	}
	sqlite3_finalize(statement);
}

- (void) updateCategoryNameMaxWidth
{
	float maxWidth = 0;
	for( Category* c in model.categories )
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
    InsulinType* insulin = [InsulinType newInsulinTypeWithName:name database:model.database];
    [model.insulinTypes addObject:insulin];
    [insulin release];
}

// Purge an InsulinType record from the database and the insulinTypes array
- (void) purgeInsulinTypeAtIndex:(unsigned)index
{
	InsulinType *const type = [model.insulinTypes objectAtIndex:index];
	const unsigned typeID = [type typeID];
	[LogEntry deleteDosesForInsulinTypeID:typeID fromDatabase:model.database];
	[type deleteFromDatabase:model.database];
    [self removeDefaultInsulinType:type];   // Must be before deleting the InsulinType
	[self removeInsulinTypeAtIndex:index];

	// Remove all of the LogEntry doses with the deleted insulin type
	for( LogDay* s in model.days )
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
    [model.insulinTypesForNewEntries removeObjectIdenticalTo:type];
	[self flushDefaultInsulinTypes];
}

// Remove an InsulinType record and generate a KV notification
- (void) removeInsulinTypeAtIndex:(unsigned)index
{
    [model.insulinTypesForNewEntries removeObjectAtIndex:index];
}

// Flush the insulin types list to the database
//  !! This truncates the table first, then writes the entire array !!
- (void) flushInsulinTypes
{
	// Truncate the category table
	sqlite3_exec(model.database, "DELETE FROM InsulinTypes", NULL, NULL, NULL);

	static char *sql = "INSERT INTO InsulinTypes (typeID, sequence, shortName) VALUES(?,?,?)";
	sqlite3_stmt *statement;
	if( sqlite3_prepare_v2(model.database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(model.database));

	unsigned i = 0;
	for( InsulinType* type in model.insulinTypes )
	{
		sqlite3_bind_int(statement, 1, type.typeID);
		sqlite3_bind_int(statement, 2, i);
		sqlite3_bind_text(statement, 3, [type.shortName UTF8String], -1, SQLITE_TRANSIENT);
		int success = sqlite3_step(statement);
		sqlite3_reset(statement);		// Reset the query for the next use
		sqlite3_clear_bindings(statement);	//Clear all bindings for next time
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(model.database));
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
    [type flush:model.database];
    [self updateInsulinTypeShortNameMaxWidth];
}

- (void) updateInsulinTypeShortNameMaxWidth
{
	float maxWidth = 0;
	for( InsulinType* t in model.insulinTypes )
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
	}
	return service;
}

- (void) setUserCredentialsWithUsername:(NSString*)user password:(NSString*)pass
{
	[self.docService setUserCredentialsWithUsername:user password:pass];
}

#pragma mark -
#pragma mark Properties

// This is a dummy property to get KVO to work on the dummy entries key
- (NSMutableArray*)entries
{
	return nil;
}

@end
