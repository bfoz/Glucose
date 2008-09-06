//
//  LogEntry.m
//  Glucose
//
//  Created by Brandon Fosdick on 6/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "LogEntry.h"
#import "InsulinDose.h"
#import "InsulinType.h"

static AppDelegate* appDelegate;

// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *delete_statement = nil;
static sqlite3_stmt *hydrate_statement = nil;
static sqlite3_stmt *flush_statement = nil;

static const char *const flush_sql = "UPDATE localLogEntries SET timestamp=?, glucose=?, glucoseUnits=?, categoryID=?, dose0=?, dose1=?, typeID0=?, typeID1=?, note=? WHERE ID=?";
//static const char *const flush_sql = "UPDATE localLogEntries SET timestamp=datetime(?,'unixepoch'), glucose=?, glucoseUnits=?, categoryID=?, dose0=?, dose1=?, typeID0=?, typeID1=?, note=? WHERE ID=?";
static const char *const init_sql = "SELECT timestamp, glucose, glucoseUnits, categoryID, dose0, dose1, typeID0, typeID1, note FROM localLogEntries WHERE ID=?";

@implementation LogEntry

@synthesize entryID, category, dirty;
@synthesize glucose;
@synthesize insulin;
@synthesize note;
@synthesize	timestamp;

// Creates a new empty LogEntry record in the database and returns the new entryID
+ (unsigned)insertNewLogEntryIntoDatabase:(sqlite3*)database
{
    if( !insert_statement )
	{
        static char *sql = "INSERT INTO localLogEntries (timestamp) VALUES(strftime('%s',datetime('NOW')))";
        if( sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK )
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    int success = sqlite3_step(insert_statement);
    sqlite3_reset(insert_statement);	// Reset instead of finalize so the statement can be reused
    if( success != SQLITE_ERROR )
        return sqlite3_last_insert_rowid(database);

    NSAssert1(0, @"Failed to insert: '%s'.", sqlite3_errmsg(database));
    return -1;
}

// Finalize (delete) all of the SQLite compiled queries.
+ (void)finalizeStatements
{
    if (insert_statement) sqlite3_finalize(insert_statement);
    if (init_statement) sqlite3_finalize(init_statement);
    if (delete_statement) sqlite3_finalize(delete_statement);
    if (hydrate_statement) sqlite3_finalize(hydrate_statement);
    if (flush_statement) sqlite3_finalize(flush_statement);
}

- (id)init
{
	if( self = [super init] )
    {
		insulin = [[NSMutableArray alloc] init];
		if( !appDelegate )
			appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	}
    return self;		
}

- (id)initWithID:(unsigned)eid database:(sqlite3 *)db
{
    if( self = [self init] )
    {
		entryID = eid;

        if( !init_statement && (sqlite3_prepare_v2(db, init_sql, -1, &init_statement, NULL) != SQLITE_OK) )
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));

        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(init_statement, 1, entryID);

#define ASSIGN_NOT_NULL(_s, _c, _var, _val)			\
if( SQLITE_NULL == sqlite3_column_type(_s, _c) )	\
		_var = nil;									\
else												\
		_var = _val;
		
        if( sqlite3_step(init_statement) == SQLITE_ROW )
		{
			ASSIGN_NOT_NULL(init_statement, 0, self.timestamp,
							[NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(init_statement, 0)]);
			ASSIGN_NOT_NULL(init_statement, 1, self.glucose,
							[NSNumber numberWithInt:sqlite3_column_int(init_statement, 1)]);
			ASSIGN_NOT_NULL(init_statement, 8, self.note,
							[NSString stringWithUTF8String:(const char*)sqlite3_column_text(init_statement, 8)]);

			if( SQLITE_NULL == sqlite3_column_type(init_statement, 3) )
				self.category = nil;
			else
				[self setCategoryWithID:sqlite3_column_int(init_statement, 3)];

			if( (SQLITE_NULL != sqlite3_column_type(init_statement, 4)) && 
			    (SQLITE_NULL != sqlite3_column_type(init_statement, 6)) )
			{
				// If insulinTypes is sorted typeID = index + 1
				[self.insulin addObject:[InsulinDose withType:[appDelegate.insulinTypes objectAtIndex:sqlite3_column_int(init_statement, 6)-1]]];
				[[self.insulin lastObject] setDose:[NSNumber numberWithInt:sqlite3_column_int(init_statement, 4)]];
			}
			if( (SQLITE_NULL != sqlite3_column_type(init_statement, 5)) && 
			    (SQLITE_NULL != sqlite3_column_type(init_statement, 7)) )
			{
				// If insulinTypes is sorted typeID = index + 1
				[self.insulin addObject:[InsulinDose withType:[appDelegate.insulinTypes objectAtIndex:sqlite3_column_int(init_statement, 7)-1]]];
				[[self.insulin lastObject] setDose:[NSNumber numberWithInt:sqlite3_column_int(init_statement, 5)]];
			}
		}
        else
		{
            self.timestamp = nil;
			self.glucose = nil;
			self.category = nil;
		}

        sqlite3_reset(init_statement);	// Reset the statement for future reuse
        dirty = NO;
	}
    return self;
}

- (void)dealloc
{
	[category release];
	[glucose release];
	[insulin release];
	[note release];
	[timestamp release];
	[super dealloc];
}

- (void)deleteFromDatabase:(sqlite3 *)db
{
    // Compile the delete statement if needed.
    if( !delete_statement )
	{
        const char *delete_sql = "DELETE FROM localLogEntries WHERE ID=?";
        if (sqlite3_prepare_v2(db, delete_sql, -1, &delete_statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
    }

    sqlite3_bind_int(delete_statement, 1, entryID);
    int success = sqlite3_step(delete_statement);
    sqlite3_reset(delete_statement);
    if( success != SQLITE_DONE )
        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(db));
}

// Flush the entry to the database if needed
- (void) flush:(sqlite3 *)db
{
	if( !dirty )
		return;

	if( !flush_statement && (sqlite3_prepare_v2(db, flush_sql, -1, &flush_statement, NULL) != SQLITE_OK) )
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));

	// Remove invalid doses before writing to the database
	{
		// Enumerate a copy of the array because arrays can't be mutated while being enumerated
		NSMutableArray* a = [NSArray arrayWithArray:insulin];
		// Iterate backwards because deleting an element changes the indices of all subsequent elements
		unsigned i = [insulin count];
		NSEnumerator* j = [a reverseObjectEnumerator];
		for( InsulinDose* d in j )
		{
			if( !d.dose || [d.dose isEqualToNumber:[NSNumber numberWithInt:0]])
				[insulin removeObjectAtIndex:--i];
		}
	}
	// Set note to nil if it has zero length
	if( note && ![note length] )
		self.note = nil;
	
	sqlite3_bind_int(flush_statement, 1, [timestamp timeIntervalSince1970]);

	if( glucose && ![glucose isEqualToNumber:[NSNumber numberWithInt:0]] )
		sqlite3_bind_double(flush_statement, 2, [glucose doubleValue]);

	sqlite3_bind_int(flush_statement, 3, 0);	// glucoseUnits

	if( category )
		sqlite3_bind_int(flush_statement, 4, [self.category categoryID]);

	unsigned i = 0;
	for( InsulinDose* dose in self.insulin )
	{
		if( i >= 2 )	// Limit to two doses for now
			break;
		sqlite3_bind_int(flush_statement, 5+i, [dose.dose intValue]);
		sqlite3_bind_int(flush_statement, 7+i, [dose.type typeID]);
		++i;
	}

	if( note && [note length] )
		sqlite3_bind_text(flush_statement, 9, [note UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(flush_statement, 10, entryID);

	// Execute the query.
	int success = sqlite3_step(flush_statement);
	sqlite3_reset(flush_statement);		// Reset the query for the next use
	sqlite3_clear_bindings(flush_statement);	//Clear all bindings for next time
	if( success != SQLITE_DONE )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(db));
	
	dirty = NO;		// Squeaky clean
}

// When entering edit mode setup defaults for any missing fields (like insulin doses)
- (void) setEditing
{
	// If the insulin array is empty, populate it with the list of default entries from the prefs bundle
	if( ![insulin count] )
	{
		for( InsulinType* t in appDelegate.defaultInsulinTypes )
			[insulin addObject:[InsulinDose withType:t]];
		dirty = YES;
	}
	else while( [insulin count] < 2 )	// If the array is partially full, pad with blanks
	{
		[insulin addObject:[InsulinDose alloc]];
		dirty = YES;
	}
}
/*
- (void)dehydrate:(sqlite3 *)db
{
	[self flush:db];

	// Release member variables to reclaim memory. Set to nil to avoid over-releasing them 
    // if dehydrate is called multiple times.

 hydrated = NO;
}
*/
#pragma mark -
#pragma mark Properties

- (void) setCategoryWithID:(unsigned)cid
{
	// As long as the categories array is sorted the categoryID = index + 1
	self.category = [appDelegate.categories objectAtIndex:cid-1];
}

- (void) setCategory:(Category*)c
{
	if( category != c )
	{
		[category release];
		category = c;
		[category retain];
		dirty = YES;
	}
}

- (void) setDose:(NSNumber*)d insulinDose:(InsulinDose*)dose
{
	if( dose && d && ![dose.dose isEqualToNumber:d] )
	{
		dose.dose = d;
		dirty = YES;
	}
}

- (void) setDose:(NSNumber*)d at:(unsigned)index
{
	InsulinDose* dose = [self.insulin objectAtIndex:index];
	[self setDose:d insulinDose:dose];
}

- (void) setDoseType:(InsulinType*)type at:(unsigned)index
{
	InsulinDose* dose = [self.insulin objectAtIndex:index];
	if( dose && type && (dose.type != type) )
	{
		dose.type = type;
		dirty = YES;
	}
}

- (void) setGlucose:(NSNumber*)g
{
	if( (glucose == g) || [glucose isEqualToNumber:g] )
		return;

	[glucose release];
	glucose = g;
	[glucose retain];
	dirty = YES;
}

- (void) setNote:(NSString*)n
{
    if ((!note && !n) || (note && n && [note isEqualToString:n])) return;
    dirty = YES;
    [note release];
    note = [n copy];	
}

- (void) setTimestamp:(NSDate*)ts
{
	if( timestamp != ts )
	{
		[timestamp release];
		timestamp = ts;
		[timestamp retain];
		dirty = YES;
	}
}

@end
