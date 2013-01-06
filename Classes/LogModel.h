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
    NSNumber*	    categoryNameMaxWidth;
    NSMutableArray* days;
    NSUserDefaults* defaults;
    NSMutableArray* insulinTypes;
    NSMutableArray* insulinTypesForNewEntries;
    NSNumber*	    insulinTypeShortNameMaxWidth;
    NSDateFormatter* shortDateFormatter;
}

@property (unsafe_unretained, nonatomic, readonly)	NSArray*    categories;
@property (nonatomic, readonly)	unsigned    categoryNameMaxWidth;
@property (nonatomic, readonly)	sqlite3*    database;
@property (nonatomic, readonly)	NSMutableArray*    days;
@property (unsafe_unretained, nonatomic, readonly)	NSArray*    insulinTypes;
@property (unsafe_unretained, nonatomic, readonly)	NSArray*    insulinTypesForNewEntries;
@property (nonatomic, readonly)	unsigned    insulinTypeShortNameMaxWidth;
@property (nonatomic, readonly)	unsigned    numberOfLoadedLogDays;
@property (nonatomic, readonly)	unsigned    numberOfLogDays;

- (id) init;
- (NSString*) shortStringFromDate:(NSDate*)date;

- (void) close;
- (void) flush;

#pragma mark Categories

- (void) addCategory:(Category*)category;
- (void) addCategoryWithName:(NSString*)name;
- (Category*) categoryForCategoryID:(unsigned)categoryID;
- (void) moveCategoryAtIndex:(unsigned)from toIndex:(unsigned)to;
- (void) purgeCategory:(Category*)category;
- (void) updateCategory:(Category*)category;
- (void) restoreBundledCategories;

# pragma mark Insulin Types

- (void) addInsulinType:(InsulinType*)type;
- (void) addInsulinTypeWithName:(NSString*)name;
- (void) flushInsulinTypes;
- (InsulinType*) insulinTypeForInsulinTypeID:(unsigned)typeID;
- (void) moveInsulinTypeAtIndex:(unsigned)from toIndex:(unsigned)to;
- (void) purgeInsulinType:(InsulinType*)type;
- (void) removeInsulinType:(InsulinType*)type;
- (void) updateInsulinType:(InsulinType*)type;
- (void) restoreBundledInsulinTypes;

#pragma mark Insulin Types for New Entries

- (void) addInsulinTypeForNewEntries:(InsulinType*)type;
- (void) flushInsulinTypesForNewEntries;
- (void) removeInsulinTypeForNewEntries:(InsulinType*)type;
- (void) removeInsulinTypeForNewEntriesAtIndex:(unsigned)index;

#pragma mark Log Days
- (void) deleteLogDay:(LogDay*)day;
- (LogDay*) logDayAtIndex:(unsigned)index;
- (LogDay*) logDayForDate:(NSDate*)d;

#pragma mark Log Entries
- (NSMutableArray*) logEntriesForDay:(LogDay*)day;
- (LogEntry*) logEntryAtIndex:(unsigned)entry inDay:(LogDay*)day;
- (LogEntry*) logEntryAtIndex:(unsigned)entry inDayIndex:(unsigned)day;
- (unsigned) numberOfEntriesForLogDayAtIndex:(unsigned)index;

- (LogEntry*) createLogEntry;
- (void) deleteLogEntry:(LogEntry*)entry inDay:(LogDay*)day;
- (void) moveLogEntry:(LogEntry*)entry fromDay:(LogDay*)from toDay:(LogDay*)to;

@end
