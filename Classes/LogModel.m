#import <sqlite3.h>

#import "LogModel.h"

#import "Constants.h"
#import "LogDay.h"
#import "LogEntry.h"

#define	LOG_SQL		@"glucose.sqlite"

@implementation LogModel

@synthesize days;

- (id) init
{
    self = [super init];
    if( self )
    {
	days = [[NSMutableArray alloc] init];
	defaults = [NSUserDefaults standardUserDefaults];
    }

    return self;
}

- (void) close
{
    if( database )
    {
	sqlite3_close(database);
	database = NULL;
    }
    
    // Do any necessary cleanup
    [LogEntry finalizeStatements];
}

- (void) flush
{
    for( LogDay* day in days )
	for( LogEntry* entry in day.entries )
	    [entry flush:database];
}

#pragma mark Log Days

- (void) deleteLogDay:(LogDay*)day
{
    // Delete all of the LogDay's entries from the database
    [day deleteAllEntriesFromDatabase:self.database];

    // Remove the LogDay itself
    [days removeObjectIdenticalTo:day];
}

- (LogDay*) logDayAtIndex:(unsigned)index
{
    const unsigned count = [days count];
    if( index < count )
	return [days objectAtIndex:index];
    if( index < numberOfLogDays )
    {
	/* At this point count <= index < numberOfLogDays, which implies that
	    count < numberOfLogDays. Therefore, there is at least one more day
	    that can be loaded.	*/
	const unsigned num = [LogDay loadDays:days
				 fromDatabase:self.database
					limit:(index-count+1)
				       offset:count];
	if( index < (count+num) )
	    return [days objectAtIndex:index];
    }
    return NULL;
}

#pragma mark Log Entries

- (NSMutableArray*) logEntriesForDay:(LogDay*)day
{
    if( day && day.count && ![day.entries count] )
	[day hydrate:database];
    return day.entries;
}

- (LogEntry*) logEntryAtIndex:(unsigned)entry inDay:(LogDay*)day
{
    NSMutableArray* entries = [self logEntriesForDay:day];
    return (entry >= [entries count]) ? nil : [entries objectAtIndex:entry];
}

- (LogEntry*) logEntryAtIndex:(unsigned)entry inDayIndex:(unsigned)day
{
    return [self logEntryAtIndex:entry inDay:[self logDayAtIndex:day]];
}

- (unsigned) numberOfEntriesForLogDayAtIndex:(unsigned)index
{
    return [[self logDayAtIndex:index] count];
}

- (LogEntry*) createLogEntry
{
    LogEntry* entry = [LogEntry createLogEntryInDatabase:database];

    /* Set defaults for the new LogEntry
	Don't use the returned string directly because glucoseUnits is used
	elsewhere in pointer comparisons (for performance reasons).
	Consequently, it must be a pointer to one of the constants in
	Constants.h.   */
    if( [[defaults objectForKey:kDefaultGlucoseUnits] isEqualToString:kGlucoseUnits_mgdL] )
	entry.glucoseUnits = kGlucoseUnits_mgdL;
    else
	entry.glucoseUnits = kGlucoseUnits_mmolL;

    return entry;
}

// Delete the given entry from the given LogDay. Remove the LogDay if it becomes empty.
- (void) deleteLogEntry:(LogEntry*)entry inDay:(LogDay*)day
{
    [day deleteEntry:entry fromDatabase:database];

    if( 0 == day.count )
	[days removeObjectIdenticalTo:day];
}

- (void) moveLogEntry:(LogEntry*)entry fromDay:(LogDay*)from toDay:(LogDay*)to
{
    [to insertEntry:entry];			// Add entry to new section
    [self deleteLogEntry:entry inDay:from];	// Remove from old section
}

#pragma mark -
#pragma mark Accessors

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

        numberOfLogDays = [LogDay numberOfDays:database];
    }

    return database;
}

- (unsigned) numberOfLoadedLogDays
{
    return [days count];
}

/* If the number of log days is requested before the database has been opened,
    open it and count the days. Otherwise, return the available number.	*/
- (unsigned) numberOfLogDays
{
    return numberOfLogDays;
//    return numberOfLogDays ? numberOfLogDays : [LogDay numberOfDays:self.database];
}

@end
