#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class Category;
@class InsulinType;
@class LogDay;
@class LogEntry;

@interface LogModel : NSObject
{
    unsigned	    numberOfLogDays;	// Number of LogDays available in the database

@private
    NSMutableArray* categories;
    sqlite3*	    database;		// SQLite database handle
    NSMutableArray* days;
    NSUserDefaults* defaults;
    NSMutableArray* insulinTypes;
    NSMutableArray* insulinTypesForNewEntries;
}

@property (nonatomic, readonly)	NSArray*    categories;
@property (nonatomic, readonly)	sqlite3*    database;
@property (nonatomic, readonly)	NSMutableArray*    days;
@property (nonatomic, readonly)	NSArray*    insulinTypes;
@property (nonatomic, readonly)	NSArray*    insulinTypesForNewEntries;
@property (nonatomic, readonly)	unsigned    numberOfLoadedLogDays;
@property (nonatomic, readonly)	unsigned    numberOfLogDays;

- (id) init;

- (void) close;
- (void) flush;

#pragma mark Categories

- (Category*) categoryForCategoryID:(unsigned)categoryID;

# pragma mark Insulin Types

- (InsulinType*) insulinTypeForInsulinTypeID:(unsigned)typeID;

#pragma mark Log Days
- (void) deleteLogDay:(LogDay*)day;
- (LogDay*) logDayAtIndex:(unsigned)index;

#pragma mark Log Entries
- (NSMutableArray*) logEntriesForDay:(LogDay*)day;
- (LogEntry*) logEntryAtIndex:(unsigned)entry inDay:(LogDay*)day;
- (LogEntry*) logEntryAtIndex:(unsigned)entry inDayIndex:(unsigned)day;
- (unsigned) numberOfEntriesForLogDayAtIndex:(unsigned)index;

- (LogEntry*) createLogEntry;
- (void) deleteLogEntry:(LogEntry*)entry inDay:(LogDay*)day;
- (void) moveLogEntry:(LogEntry*)entry fromDay:(LogDay*)from toDay:(LogDay*)to;

@end
