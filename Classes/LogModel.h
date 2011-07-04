#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class LogDay;
@class LogEntry;

@interface LogModel : NSObject
{
    unsigned	    numberOfLogDays;	// Number of LogDays available in the database

@private
    sqlite3*	    database;		// SQLite database handle
    NSMutableArray* days;
    NSUserDefaults* defaults;
}

@property (nonatomic, readonly)	sqlite3*    database;
@property (nonatomic, readonly)	NSMutableArray*    days;
@property (nonatomic, readonly)	unsigned    numberOfLoadedLogDays;
@property (nonatomic, readonly)	unsigned    numberOfLogDays;

- (id) init;

- (void) close;
- (void) flush;

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
