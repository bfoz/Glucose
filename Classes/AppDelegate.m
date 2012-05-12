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

@interface AppDelegate () <LogViewDelegate>

- (void) createEditableCopyOfDatabaseIfNeeded;

@end

@implementation AppDelegate

@synthesize window;
@synthesize navController;

NSDateFormatter* shortDateFormatter = nil;

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
    NSArray *const a = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], // Aspart
						 [NSNumber numberWithInt:6], // NPH
						 nil];
	NSArray* keys = [NSArray arrayWithObjects:kHighGlucoseWarning0, kLowGlucoseWarning0, kHighGlucoseWarning1, kLowGlucoseWarning1, kDefaultGlucoseUnits, kDefaultInsulinPrecision, kDefaultInsulinTypes, kExportGoogleShareEnable, nil];
	NSArray* values = [NSArray arrayWithObjects:@"120", @"80", @"6.6", @"4.4", kGlucoseUnits_mgdL, [NSNumber numberWithInt:0], a, @"NO", nil];
	NSDictionary* d = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	[[NSUserDefaults standardUserDefaults] registerDefaults:d];

    // Create the Log Model object
    model = [[LogModel alloc] init];
    if( !model )
    {
	NSLog(@"Could not create a LogModel");
	return NO;
    }

    LogViewController* logViewController = [[LogViewController alloc] initWithModel:model delegate:self];
    UINavigationController* aNavigationController = [[UINavigationController alloc] initWithRootViewController:logViewController];
    self.navController = aNavigationController;

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

    // Create an empty "Today" object if no LogDays are available
    if( 0 == [model numberOfLogDays] )
    {
	NSDate *const day = [NSDate date];
	LogDay *const section = [[LogDay alloc] initWithDate:day];
	section.name = [shortDateFormatter stringFromDate:day];
	[model.days addObject:section];
	[section release];
    }
    else    // Otherwise, load the first LogDay from the database
	[model logDayAtIndex:0];

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
	[model addCategory:c];
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
	[model addInsulinType:t];
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

- (unsigned) numberOfLogEntriesForCategory:(Category*)category
{
    return [LogEntry numLogEntriesForCategoryID:category.categoryID database:model.database];
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
