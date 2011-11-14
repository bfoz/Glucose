#import <sqlite3.h>

#import "LogModel.h"

#import "Constants.h"
#import "Category.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogDay.h"
#import "LogEntry.h"

#define	LOG_SQL		@"glucose.sqlite"

@interface LogModel ()

- (void) clearCategoryNameMaxWidth;
- (void) clearInsulinTypeShortNameMaxWidth;
- (void) flushCategories;
- (void) removeCategory:(Category*)type;

@end

@implementation LogModel

@synthesize days;

- (id) init
{
    self = [super init];
    if( self )
    {
	days = [[NSMutableArray alloc] init];
	defaults = [NSUserDefaults standardUserDefaults];
	insulinTypeShortNameMaxWidth = NULL;
	shortDateFormatter = [[NSDateFormatter alloc] init];
	[shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
    }

    return self;
}

- (NSString*) shortStringFromDate:(NSDate*)date
{
    return [shortDateFormatter stringFromDate:date];
}

- (void) close
{
    if( database )
    {
	[LogEntry finalize];

	sqlite3_close(database);
	database = NULL;
    }
}

- (void) flush
{
    [self flushInsulinTypes];
    [self flushInsulinTypesForNewEntries];
    for( LogDay* day in days )
	for( LogEntry* entry in day.entries )
	    [entry flush:self.database];
}

#pragma mark
#pragma mark Categories

- (void) addCategory:(Category*)category
{
    if( ![categories containsObject:category] )
    {
	[Category insertCategory:category intoDatabase:self.database];
	[categories addObject:category];
    }
    [self clearCategoryNameMaxWidth];
}

- (void) addCategoryWithName:(NSString*)name
{
    Category *const category = [Category newCategoryWithName:name
						    database:self.database];
    [categories addObject:category];
    [category release];
    [self clearCategoryNameMaxWidth];
}

- (Category*) categoryForCategoryID:(unsigned)categoryID
{
    for( Category* category in self.categories )
	if( category.categoryID == categoryID )
	    return category;
    return NULL;
}

- (unsigned) categoryNameMaxWidth
{
    if( !categoryNameMaxWidth )
    {
	float maxWidth = 0;
	for( Category* c in self.categories )
	{
	    const float a = [c.categoryName sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]].width;
	    if( a > maxWidth )
		maxWidth = a;
	}
	if( maxWidth != 0 )
	    categoryNameMaxWidth = [[NSNumber numberWithFloat:maxWidth] retain];
	else
	    return 0;
    }
    return [categoryNameMaxWidth unsignedIntValue];
}

// Clear the max width so it will be recomputed next time it's needed
- (void) clearCategoryNameMaxWidth
{
    if( categoryNameMaxWidth )
	[categoryNameMaxWidth release];
    categoryNameMaxWidth = NULL;
}

// Flush the category list to the database
- (void) flushCategories
{
    static char *sql = "REPLACE INTO LogEntryCategories (categoryID, sequence, name) VALUES(?,?,?)";
    sqlite3_stmt *statement;
    if( sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL) != SQLITE_OK )
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

- (void) moveCategoryAtIndex:(unsigned)from toIndex:(unsigned)to
{
    Category *const c = [[self.categories objectAtIndex:from] retain];

    /* The previous line lazy-instantiated the categories array, so there's no
	longer a need to use the accessor method. */
    [categories removeObjectAtIndex:from];
    [categories insertObject:c atIndex:to];

    // Flush the array to preserve the new sequence
    [self flushCategories];

    [c release];
}

// Purge a Category record from the database and the category array
- (void) purgeCategory:(Category*)category
{
    // Move all LogEntries in the deleted category to category "None"
    NSArray* a = [NSArray arrayWithArray:self.days];
    for( LogDay* s in a )
    {
	NSArray* entries = [NSArray arrayWithArray:s.entries];
	for( LogEntry* e in entries )
	    if( e.category && (e.category == category) )
		e.category = nil;;
    }

    [LogEntry moveAllEntriesInCategory:category toCategory:nil database:self.database];
    [Category deleteCategory:category fromDatabase:self.database];
    [self removeCategory:category];
}

- (void) removeCategory:(Category*)type
{
    [categories removeObject:type];
    [self clearCategoryNameMaxWidth];
}

- (void) updateCategory:(Category*)category
{
    [category flush:self.database];
    [self clearCategoryNameMaxWidth];
}

#pragma mark
#pragma mark Insulin Types

- (void) addInsulinType:(InsulinType*)type
{
    if( ![insulinTypes containsObject:type] )
    {
	[InsulinType insertInsulinType:type intoDatabase:self.database];
	[insulinTypes addObject:type];
    }
    [self clearInsulinTypeShortNameMaxWidth];
}

- (void) addInsulinTypeWithName:(NSString*)name
{
    InsulinType *const type = [InsulinType newInsulinTypeWithName:name
							 database:self.database];
    [insulinTypes addObject:type];
    [type release];
    [self clearInsulinTypeShortNameMaxWidth];
}

// Clear the max width so it will be recomputed next time it's needed
- (void) clearInsulinTypeShortNameMaxWidth
{
    if( insulinTypeShortNameMaxWidth )
	[insulinTypeShortNameMaxWidth release];
    insulinTypeShortNameMaxWidth = NULL;
}

// Flush the insulin types list to the database
- (void) flushInsulinTypes
{
    static char *sql = "REPLACE INTO InsulinTypes (typeID, sequence, shortName) VALUES(?,?,?)";
    sqlite3_stmt *statement;
    if( sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL) != SQLITE_OK )
	NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));

    unsigned i = 0;
    for( InsulinType* type in insulinTypes )
    {
	sqlite3_bind_int(statement, 1, type.typeID);
	sqlite3_bind_int(statement, 2, i);
	sqlite3_bind_text(statement, 3, [type.shortName UTF8String], -1, SQLITE_TRANSIENT);
	int success = sqlite3_step(statement);
	sqlite3_reset(statement);		// Reset the query for the next use
	sqlite3_clear_bindings(statement);	// Clear all bindings for next time
	if( success != SQLITE_DONE )
	    NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(database));
	++i;
    }
    sqlite3_finalize(statement);
}

- (InsulinType*) insulinTypeForInsulinTypeID:(unsigned)typeID
{
    for( InsulinType* t in self.insulinTypes )
	if( t.typeID == typeID )
	    return t;
    return NULL;
}

- (unsigned) insulinTypeShortNameMaxWidth
{
    if( !insulinTypeShortNameMaxWidth )
    {
	float maxWidth = 0;
	for( InsulinType* t in self.insulinTypes )
	{
	    const float a = [t.shortName sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]].width;
	    if( a > maxWidth )
		maxWidth = a;
	}
	if( maxWidth != 0 )
	    insulinTypeShortNameMaxWidth = [[NSNumber numberWithFloat:maxWidth] retain];
	else
	    return 0;
    }
    return [insulinTypeShortNameMaxWidth unsignedIntValue];
}

- (void) moveInsulinTypeAtIndex:(unsigned)from toIndex:(unsigned)to
{
    InsulinType *const type = [[self.insulinTypes objectAtIndex:from] retain];

    /* The previous line lazy-instantiated the insulin types array, so there's
	no longer a need to use the accessor method. */
    [insulinTypes removeObjectAtIndex:from];
    [insulinTypes insertObject:type atIndex:to];

    // Flush the array to preserve the new sequence
    [self flushInsulinTypes];

    [type release];
}

// Purge an InsulinType record from the database and the insulinTypes array
- (void) purgeInsulinType:(InsulinType*)type
{
    const unsigned typeID = [type typeID];
    [LogEntry deleteDosesForInsulinTypeID:typeID fromDatabase:self.database];
    [type deleteFromDatabase:self.database];
    [self removeInsulinType:type];

    // Remove all of the LogEntry doses with the deleted insulin type
    for( LogDay* s in self.days )
    {
	for( LogEntry* e in s.entries )
	{
	    NSArray* doses = [NSArray arrayWithArray:e.insulin];
	    for( InsulinDose* d in doses )
		if( d.type && (d.type == type) )
		    [e.insulin removeObjectIdenticalTo:d];
	}
    }
    [self clearInsulinTypeShortNameMaxWidth];
}

- (void) removeInsulinType:(InsulinType*)type
{
    [self removeInsulinTypeForNewEntries:type];
    [insulinTypes removeObject:type];
    [self clearInsulinTypeShortNameMaxWidth];
}

- (void) updateInsulinType:(InsulinType*)type
{
    [type flush:self.database];
    [self clearInsulinTypeShortNameMaxWidth];
}

#pragma mark
#pragma mark Insulin Types for New Entries

- (void) addInsulinTypeForNewEntries:(InsulinType*)type
{
    [insulinTypesForNewEntries addObject:type];
    [self flushInsulinTypesForNewEntries];
}

int orderInsulinTypesByIndex(id left, id right, void* insulinTypes)
{
    unsigned a = [((NSMutableArray*)insulinTypes) indexOfObjectIdenticalTo:left];
    unsigned b = [((NSMutableArray*)insulinTypes) indexOfObjectIdenticalTo:right];
    if( a < b )
	return NSOrderedAscending;
    if( a == b )
	return NSOrderedSame;
    return NSOrderedDescending;
}

- (void) flushInsulinTypesForNewEntries
{
    const unsigned count = [insulinTypesForNewEntries count];
    NSMutableArray *const a = [NSMutableArray arrayWithCapacity:count];

    for( InsulinType* type in insulinTypesForNewEntries )
	[a addObject:[NSNumber numberWithInt:type.typeID]];

    /* Sort the array before flushing it to keep it in the same order as the
	insulinTypes array. The NewLogEntry view uses the array order when
	displaying new dose rows.   */
    [insulinTypesForNewEntries sortUsingFunction:orderInsulinTypesByIndex
					 context:insulinTypes];

    [[NSUserDefaults standardUserDefaults] setObject:a
					      forKey:kDefaultInsulinTypes];
}

- (void) removeInsulinTypeForNewEntries:(InsulinType*)type
{
    if( [insulinTypesForNewEntries containsObject:type] )
    {
	[insulinTypesForNewEntries removeObjectIdenticalTo:type];
	[self flushInsulinTypesForNewEntries];
    }
}

- (void) removeInsulinTypeForNewEntriesAtIndex:(unsigned)index
{
    [insulinTypesForNewEntries removeObjectAtIndex:index];
    [self flushInsulinTypesForNewEntries];
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

static const unsigned DATE_COMPONENTS_FOR_DAY = (NSYearCalendarUnit |
						 NSMonthCalendarUnit |
						 NSDayCalendarUnit);

- (LogDay*) logDayForDate:(NSDate*)date
{
    NSCalendar *const calendar = [NSCalendar currentCalendar];
    NSDateComponents *const _date = [calendar components:DATE_COMPONENTS_FOR_DAY
					        fromDate:date];
    for( LogDay* s in self.days )
    {
	NSDateComponents *const c = [calendar components:DATE_COMPONENTS_FOR_DAY
						fromDate:s.date];
	if( (_date.day == c.day) &&
	    (_date.month == c.month) &&
	    (_date.year == c.year) )
	    return s;
    }

    LogDay* day = [[LogDay alloc] initWithDate:date];
    day.name = [shortDateFormatter stringFromDate:date];

    /* At this point it's already known that the given date doesn't match
    	anything in the array. So, only need to compare seconds; no need to
    	create calendar components. */

    // Find the index that the new LogDay should be inserted at
    unsigned i = 0;
    const double a = [date timeIntervalSince1970];
    for( LogDay* s in self.days )
    {
	if( a > [s.date timeIntervalSince1970] )
	    break;
	++i;
    }

    [self.days insertObject:day atIndex:i];
    [day release];
    return day;
}

#pragma mark Log Entries

- (NSMutableArray*) logEntriesForDay:(LogDay*)day
{
    if( day && day.count && ![day.entries count] )
	[day hydrate:self];
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
    LogEntry* entry = [LogEntry createLogEntryInDatabase:self.database];

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
    [day deleteEntry:entry fromDatabase:self.database];

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

- (NSArray*) categories
{
    if( !categories )
    {
	categories = [[NSMutableArray alloc] init];
	[Category loadCategories:categories fromDatabase:self.database];
    }
    return categories;
}

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

- (NSArray*) insulinTypes
{
    if( !insulinTypes )
    {
	insulinTypes = [NSMutableArray new];
	[InsulinType loadInsulinTypes:insulinTypes fromDatabase:self.database];
    }

    return insulinTypes;
}

- (NSArray*) insulinTypesForNewEntries
{
    if( !insulinTypesForNewEntries )
    {
	insulinTypesForNewEntries = [NSMutableArray new];
	for( NSNumber* typeID in [defaults objectForKey:kDefaultInsulinTypes] )
	{
	    InsulinType *const t = [self insulinTypeForInsulinTypeID:[typeID intValue]];
	    if( t )
		[insulinTypesForNewEntries addObject:t];
	}
    }

    return insulinTypesForNewEntries;
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
