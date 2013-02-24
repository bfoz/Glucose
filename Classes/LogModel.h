#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class Category;
@class ManagedCategory;
@class ManagedInsulinType;
@class ManagedLogDay;
@class ManagedLogEntry;
@class LogDay;
@class LogEntry;

typedef enum
{
    kGlucoseUnitsUnknown,
    kGlucoseUnits_mgdL,
    kGlucoseUnits_mmolL,
} GlucoseUnitsType;

extern NSString* GlucoseUnitsTypeString_mgdL;
extern NSString* GlucoseUnitsTypeString_mmolL;

@interface LogModel : NSObject
{
@private
    NSNumber*	    categoryNameMaxWidth;
    NSUserDefaults* defaults;
    NSNumber*	    insulinTypeShortNameMaxWidth;
    NSDateFormatter* shortDateFormatter;
}

@property (nonatomic, strong, readonly) NSNumberFormatter*	averageGlucoseFormatter;
@property (nonatomic, strong, readonly)	NSMutableArray*	categories;
@property (nonatomic, strong, readonly)	NSMutableArray*	insulinTypes;
@property (nonatomic, strong, readonly)	NSMutableOrderedSet*	insulinTypesForNewEntries;

@property (nonatomic, readonly)	unsigned    categoryNameMaxWidth;
@property (nonatomic, strong, readonly)	NSArray*    logDays;
@property (nonatomic, readonly)	unsigned    insulinTypeShortNameMaxWidth;

+ (NSArray*) settingsNewEntryInsulinTypes;
+ (void) flushInsulinTypesForNewEntries:(NSOrderedSet*)managedInsulinTypes;

- (NSData*) csvDataFromDate:(NSDate*)startDate toDate:(NSDate*)endDate;
- (NSString*) shortStringFromDate:(NSDate*)date;

#pragma mark Settings

+ (GlucoseUnitsType) glucoseUnitsSetting;
+ (NSString*) glucoseUnitsSettingString;
+ (void) setGlucoseUnitsSetting:(GlucoseUnitsType)units;

- (unsigned) glucosePrecisionForNewEntries;

- (float) highGlucoseWarningThreshold;
- (float) lowGlucoseWarningThreshold;
- (void) setHighGlucoseWarningThreshold:(NSNumber*)threshold;
- (void) setLowGlucoseWarningThreshold:(NSNumber*)threshold;

- (NSString*) highGlucoseWarningThresholdString;
- (NSString*) lowGlucoseWarningThresholdString;

#pragma mark Categories
- (ManagedCategory*) addCategoryWithName:(NSString*)name;
- (void) moveCategoryAtIndex:(unsigned)from toIndex:(unsigned)to;
- (void) updateCategory:(ManagedCategory*)category;
- (void) removeCategory:(ManagedCategory*)category;
- (void) restoreBundledCategories;

# pragma mark Insulin Types
- (ManagedInsulinType*) addInsulinTypeWithName:(NSString*)name;
- (void) flushInsulinTypes;
- (void) moveInsulinTypeAtIndex:(unsigned)from toIndex:(unsigned)to;
- (unsigned) numberOfLogEntriesForInsulinType:(ManagedInsulinType*)insulinType;
- (void) removeInsulinType:(ManagedInsulinType*)type;
- (void) updateInsulinType:(ManagedInsulinType*)type;
- (void) restoreBundledInsulinTypes;

#pragma mark Insulin Types for New Entries

- (void) addInsulinTypeForNewEntries:(ManagedInsulinType*)type;
- (void) flushInsulinTypesForNewEntries;
- (void) removeInsulinTypeForNewEntries:(ManagedInsulinType*)type;
- (void) removeInsulinTypeForNewEntriesAtIndex:(unsigned)index;

#pragma mark Log Days
- (void) deleteLogDay:(ManagedLogDay*)day;
- (ManagedLogDay*) logDayForDate:(NSDate*)d;

#pragma mark Log Entries
- (NSDate*) dateOfEarliestLogEntry;
- (unsigned) numberOfLogEntriesFromDate:(NSDate*)fromDate toDate:(NSDate*)toDate;

- (ManagedLogEntry*) logEntryAtIndex:(unsigned)entry inDayIndex:(unsigned)day;

+ (ManagedLogDay*) insertManagedLogDayIntoContext:(NSManagedObjectContext*)managedObjectContext;
- (ManagedLogEntry*) insertManagedLogEntry;

- (void) commitChanges;
- (void) save;
- (void) undo;

- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to;
- (void) deleteLogEntry:(ManagedLogEntry*)logEntry fromDay:(ManagedLogDay*)logDay;

@end
