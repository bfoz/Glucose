#import <CoreData/CoreData.h>
#import <sqlite3.h>

#import "LogModel.h"
#import "LogModel+CoreData.h"
#import "LogModel+SQLite.h"

#import "ManagedCategory.h"
#import "ManagedInsulinDose.h"
#import "ManagedInsulinType.h"
#import "ManagedLogDay.h"
#import "ManagedLogEntry+App.h"

#import "Constants.h"
#import "Category.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogEntry.h"

#define	kSettingsGlucoseUnitsValue_mgdL		@0
#define	kSettingsGlucoseUnitsValue_mmolL	@1

static NSString* kSettingsGlucoseUnitsKey	= @"DefaultGlucoseUnits";
static NSString* kSettingsHighGlucoseWarningThresholdKey_mgdL	= @"HighGlucoseWarning0";
static NSString* kSettingsHighGlucoseWarningThresholdKey_mmolL	= @"HighGlucoseWarning1";
static NSString* kSettingsLowGlucoseWarningThresholdKey_mgdL	= @"LowGlucoseWarning0";
static NSString* kSettingsLowGlucoseWarningThresholdKey_mmolL	= @"HighGlucoseWarning1";

static NSNumber* kDefaultHighGlucoseWarningThreshold_mgdL;
static NSNumber* kDefaultHighGlucoseWarningThreshold_mmolL;
static NSNumber* kDefaultLowGlucoseWarningThreshold_mgdL;
static NSNumber* kDefaultLowGlucoseWarningThreshold_mmolL;

NSString* GlucoseUnitsTypeString_mgdL	= @"mg/dL";
NSString* GlucoseUnitsTypeString_mmolL	= @"mmol/L";

@interface LogModel ()

- (void) clearCategoryNameMaxWidth;
- (void) clearInsulinTypeShortNameMaxWidth;

- (NSManagedObjectContext*) managedObjectContext;

@end

@implementation LogModel
{
    NSMutableArray* _logDays;

    NSManagedObjectContext*	    _managedObjectContext;
    NSManagedObjectModel*	    _managedObjectModel;
    NSPersistentStoreCoordinator*   _persistentStoreCoordinator;
}

@synthesize categories = _categories;
@synthesize insulinTypes = _insulinTypes;
@synthesize insulinTypesForNewEntries = _insulinTypesForNewEntries;

- (id) init
{
    self = [super init];
    if( self )
    {
	kDefaultHighGlucoseWarningThreshold_mgdL   = @120;
	kDefaultLowGlucoseWarningThreshold_mgdL    = @80;

	kDefaultHighGlucoseWarningThreshold_mmolL  = @6.6;
	kDefaultLowGlucoseWarningThreshold_mmolL   = @4.4;

	defaults = [NSUserDefaults standardUserDefaults];
	insulinTypeShortNameMaxWidth = NULL;
	shortDateFormatter = [[NSDateFormatter alloc] init];
	[shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
    }

    return self;
}

- (void) dealloc
{
    _managedObjectContext = nil;
    _persistentStoreCoordinator = nil;
}

- (NSString*) shortStringFromDate:(NSDate*)date
{
    return [shortDateFormatter stringFromDate:date];
}

- (void) flush
{
    [self flushInsulinTypes];
    [self flushInsulinTypesForNewEntries];
    [self save];
}

- (NSData*) csvDataFromDate:(NSDate*)startDate toDate:(NSDate*)endDate
{
    NSMutableData* data = [NSMutableData dataWithCapacity:2048];

    if( !data )
	return nil;

    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogEntry"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(timestamp >= %@) AND (timestamp <= %@)", startDate, endDate];

    NSError* error = nil;
    NSArray* fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];

    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;

    // Append the header row
    NSString* headerString = @"timestamp,glucose,glucoseUnits,category,dose0,type0,dose1,type1,note\n";
    const char* utfHeader = [headerString UTF8String];
    [data appendBytes:utfHeader length:strlen(utfHeader)];

    for( ManagedLogEntry* logEntry in fetchedObjects )
    {
	NSMutableArray* columns = [NSMutableArray array];

	[columns addObject:[dateFormatter stringFromDate:logEntry.timestamp]];
	[columns addObject:logEntry.glucoseUnitsString];
	[columns addObject:logEntry.category.name];

	for( ManagedInsulinDose* insulinDose in logEntry.insulinDoses )
	{
	    [columns addObject:[numberFormatter stringFromNumber:insulinDose.dose]];
	    [columns addObject:insulinDose.insulinType.shortName];
	}

	if( logEntry.note )
	    [columns addObject:logEntry.note];

	[data appendBytes:"\"" length:strlen("\"")];
	[data appendData:[[columns componentsJoinedByString:@"\",\""] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendBytes:"\"\n" length:strlen("\"\n")];
    }

    return data;
}

#pragma mark Categories

- (ManagedCategory*) addCategoryWithName:(NSString*)name
{
    ManagedCategory* category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:self.managedObjectContext];
    category.name = name;
    return category;
}

- (unsigned) categoryNameMaxWidth
{
    if( !categoryNameMaxWidth )
    {
	float maxWidth = 0;
	for( ManagedCategory* c in self.categories )
	{
	    const float a = [c.name sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]].width;
	    if( a > maxWidth )
		maxWidth = a;
	}
	if( maxWidth != 0 )
	    categoryNameMaxWidth = [NSNumber numberWithFloat:maxWidth];
	else
	    return 0;
    }
    return [categoryNameMaxWidth unsignedIntValue];
}

// Clear the max width so it will be recomputed next time it's needed
- (void) clearCategoryNameMaxWidth
{
    categoryNameMaxWidth = NULL;
}

// Flush the category list to the database
- (void) flushCategories
{
    unsigned index = 0;
    for( ManagedCategory* category in self.categories )
	category.sequenceNumber = index;
    categoryNameMaxWidth = nil;
}

- (void) moveCategoryAtIndex:(unsigned)from toIndex:(unsigned)to
{
    Category *const c = [self.categories objectAtIndex:from];

    /* The previous line lazy-instantiated the categories array, so there's no
	longer a need to use the accessor method. */
    [self.categories removeObjectAtIndex:from];
    [self.categories insertObject:c atIndex:to];

    // Flush the array to preserve the new sequence
    [self flushCategories];

}

- (void) removeCategory:(ManagedCategory*)category
{
    [self.managedObjectContext deleteObject:category];
    [self.categories removeObject:category];
    [self clearCategoryNameMaxWidth];
}

- (void) updateCategory:(ManagedCategory*)category
{
    [self save];
    [self clearCategoryNameMaxWidth];
}

- (void) restoreBundledCategories
{
    sqlite3* bundledDatabase = [LogModel openDatabasePath:[LogModel bundledDatabasePath]];
    if( !bundledDatabase )
	return;

    NSArray* bundledCategories = [LogModel loadCategoriesFromDatabase:bundledDatabase];
    [LogModel closeDatabase:bundledDatabase];

    unsigned index = 0;
    for( Category* category in bundledCategories )
    {
	ManagedCategory* managedCategory = [LogModel insertManagedCategoryIntoContext:self.managedObjectContext];
	managedCategory.name = category.categoryName;
	managedCategory.sequenceNumber = index;
	++index;
    }
}

#pragma mark
#pragma mark Insulin Types

- (ManagedInsulinType*) addInsulinTypeWithName:(NSString*)name
{
    ManagedInsulinType* insulinType = [NSEntityDescription insertNewObjectForEntityForName:@"InsulinType" inManagedObjectContext:self.managedObjectContext];
    insulinType.shortName = name;
    return insulinType;
}

// Clear the max width so it will be recomputed next time it's needed
- (void) clearInsulinTypeShortNameMaxWidth
{
    insulinTypeShortNameMaxWidth = NULL;
}

// Flush the insulin types list to the database
- (void) flushInsulinTypes
{
    unsigned index = 0;
    for( ManagedInsulinType* insulinType in self.insulinTypes )
	insulinType.sequenceNumber = index;
    insulinTypeShortNameMaxWidth = NULL;
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
	    insulinTypeShortNameMaxWidth = [NSNumber numberWithFloat:maxWidth];
	else
	    return 0;
    }
    return [insulinTypeShortNameMaxWidth unsignedIntValue];
}

- (void) moveInsulinTypeAtIndex:(unsigned)from toIndex:(unsigned)to
{
    ManagedInsulinType *const type = [self.insulinTypes objectAtIndex:from];

    /* The previous line lazy-instantiated the insulin types array, so there's
	no longer a need to use the accessor method. */
    [self.insulinTypes removeObjectAtIndex:from];
    [self.insulinTypes insertObject:type atIndex:to];

    // Flush the array to preserve the new sequence
    [self flushInsulinTypes];

}

- (unsigned) numberOfLogEntriesForInsulinType:(ManagedInsulinType*)insulinType
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:self.managedObjectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"ANY insulinDoses.insulinType == %@", insulinType];

    NSError* error = nil;
    return [self.managedObjectContext countForFetchRequest:fetchRequest
						     error:&error];
}

- (void) removeInsulinType:(ManagedInsulinType*)insulinType
{
    [self removeInsulinTypeForNewEntries:insulinType];
    [self.insulinTypes removeObject:insulinType];
    [self clearInsulinTypeShortNameMaxWidth];
}

- (void) updateInsulinType:(InsulinType*)type
{
    [self save];
    [self clearInsulinTypeShortNameMaxWidth];
}

- (void) restoreBundledInsulinTypes
{
    sqlite3* bundledDatabase = [LogModel openDatabasePath:[LogModel bundledDatabasePath]];
    if( !bundledDatabase )
	return;

    NSArray* bundledInsulinTypes = [LogModel loadInsulinTypesFromDatabase:bundledDatabase];
    [LogModel closeDatabase:bundledDatabase];

    unsigned index = 0;
    for( InsulinType* insulinType in bundledInsulinTypes )
    {
	ManagedInsulinType* managedInsulinType = [LogModel insertManagedInsulinTypeIntoContext:self.managedObjectContext];
	managedInsulinType.shortName = insulinType.shortName;
	managedInsulinType.sequenceNumber = index;
	++index;
    }
}

#pragma mark
#pragma mark Insulin Types for New Entries

- (void) addInsulinTypeForNewEntries:(ManagedInsulinType*)type
{
    [self.insulinTypesForNewEntries addObject:type];
    [self flushInsulinTypesForNewEntries];
}

int orderInsulinTypesByIndex(id left, id right, void* insulinTypes)
{
    unsigned a = [((__bridge NSMutableArray*)insulinTypes) indexOfObjectIdenticalTo:left];
    unsigned b = [((__bridge NSMutableArray*)insulinTypes) indexOfObjectIdenticalTo:right];
    if( a < b )
	return NSOrderedAscending;
    if( a == b )
	return NSOrderedSame;
    return NSOrderedDescending;
}

- (void) flushInsulinTypesForNewEntries
{
    const unsigned count = [self.insulinTypesForNewEntries count];
    NSMutableArray *const a = [NSMutableArray arrayWithCapacity:count];

    for( InsulinType* type in self.insulinTypesForNewEntries )
	[a addObject:[NSNumber numberWithInt:type.typeID]];

    /* Sort the array before flushing it to keep it in the same order as the
	insulinTypes array. The NewLogEntry view uses the array order when
	displaying new dose rows.   */
    [self.insulinTypesForNewEntries sortUsingFunction:orderInsulinTypesByIndex
					      context:(__bridge void *)(self.insulinTypes)];

    [[NSUserDefaults standardUserDefaults] setObject:a
					      forKey:kDefaultInsulinTypes];
}

- (void) removeInsulinTypeForNewEntries:(ManagedInsulinType*)type
{
    if( [self.insulinTypesForNewEntries containsObject:type] )
    {
	[self.insulinTypesForNewEntries removeObjectIdenticalTo:type];
	[self flushInsulinTypesForNewEntries];
    }
}

- (void) removeInsulinTypeForNewEntriesAtIndex:(unsigned)index
{
    [self.insulinTypesForNewEntries removeObjectAtIndex:index];
    [self flushInsulinTypesForNewEntries];
}

#pragma mark Log Days

- (void) deleteLogDay:(ManagedLogDay*)managedLogDay
{
    [self.managedObjectContext deleteObject:managedLogDay];
    [_logDays removeObjectIdenticalTo:managedLogDay];
    [self save];
}

+ (ManagedLogDay*) insertManagedLogDayIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"LogDay"
					 inManagedObjectContext:managedObjectContext];
}

- (ManagedLogDay*) insertManagedLogDay
{
    return [LogModel insertManagedLogDayIntoContext:self.managedObjectContext];
}

static const unsigned DATE_COMPONENTS_FOR_DAY = (NSYearCalendarUnit |
						 NSMonthCalendarUnit |
						 NSDayCalendarUnit);

- (ManagedLogDay*) logDayForDate:(NSDate*)date
{
    NSCalendar *const calendar = [NSCalendar currentCalendar];
    NSDateComponents *const _date = [calendar components:DATE_COMPONENTS_FOR_DAY
					        fromDate:date];
    for( ManagedLogDay* logDay in self.logDays )
    {
	NSDateComponents *const c = [calendar components:DATE_COMPONENTS_FOR_DAY
						fromDate:logDay.date];
	if( (_date.day == c.day) &&
	    (_date.month == c.month) &&
	    (_date.year == c.year) )
	    return logDay;
    }

    ManagedLogDay* managedLogDay = [LogModel insertManagedLogDayIntoContext:self.managedObjectContext];
    managedLogDay.date = date;

    /* At this point it's already known that the given date doesn't match
    	anything in the array. So, only need to compare seconds; no need to
    	create calendar components. */

    // Find the index that the new LogDay should be inserted at
    unsigned i = 0;
    const double a = [date timeIntervalSince1970];
    for( ManagedLogDay* logDay in self.logDays )
    {
	if( a > [logDay.date timeIntervalSince1970] )
	    break;
	++i;
    }

    [_logDays insertObject:managedLogDay atIndex:i];
    return managedLogDay;
}

#pragma mark Log Entries

- (NSDate*) dateOfEarliestLogEntry
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogEntry"];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES]];
    fetchRequest.fetchLimit = 1;

    NSError* error = nil;
    NSArray* fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if( fetchedObjects.count )
	return [fetchedObjects objectAtIndex:0];
    return nil;
}

- (unsigned) numberOfLogEntriesFromDate:(NSDate*)startDate toDate:(NSDate*)endDate
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogEntry"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(timestamp >= %@) AND (timestamp <= %@)", startDate, endDate];

    NSError* error = nil;
    return [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
}

- (ManagedLogEntry*) logEntryAtIndex:(unsigned)index inDay:(ManagedLogDay*)logDay
{
    NSOrderedSet* entries = logDay.logEntries;
    return (index >= [entries count]) ? nil : [entries objectAtIndex:index];
}

- (ManagedLogEntry*) logEntryAtIndex:(unsigned)entry inDayIndex:(unsigned)dayIndex
{
    ManagedLogDay* logDay = [self.logDays objectAtIndex:dayIndex];
    return [logDay.logEntries objectAtIndex:entry];
}

- (ManagedLogEntry*) insertManagedLogEntry
{
    return [ManagedLogEntry insertManagedLogEntryInContext:self.managedObjectContext];
}

- (ManagedLogEntry*) insertManagedLogEntryWithUndo
{
    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];

    ManagedLogEntry* managedLogEntry = [ManagedLogEntry insertManagedLogEntryInContext:self.managedObjectContext];
    managedLogEntry.timestamp = [NSDate date];
    managedLogEntry.glucoseUnits = [NSNumber numberWithInt:[self glucoseUnitsSetting]];

    for( ManagedInsulinType* insulinType in self.insulinTypesForNewEntries )
	[managedLogEntry addDoseWithType:insulinType];

    return managedLogEntry;
}

- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to
{
    NSMutableArray* logDaysToDelete = [[NSMutableArray alloc] init];
    for( ManagedLogDay* logDay in self.logDays )
    {
	NSDate *const d = logDay.date;
	NSComparisonResult b = [from compare:d];
	NSComparisonResult c = [to compare:d];

	if( ((b == NSOrderedAscending) || (b == NSOrderedSame)) &&
	   ((c == NSOrderedDescending) || (c == NSOrderedSame)) )
	    [logDaysToDelete addObject:logDay];
    }

    for( ManagedLogDay* logDay in logDaysToDelete )
    {
	logDay.logEntries = [NSOrderedSet orderedSet];
	[self.managedObjectContext deleteObject:logDay];
	[_logDays removeObjectIdenticalTo:logDay];
    }
}

// Delete the given entry from the given LogDay. Remove the LogDay if it becomes empty.
- (void) deleteLogEntry:(ManagedLogEntry*)logEntry fromDay:(ManagedLogDay*)logDay
{
    [self.managedObjectContext deleteObject:logEntry];

    if( 0 == logDay.logEntries.count )
	[_logDays removeObjectIdenticalTo:logDay];
}

- (void) moveLogEntry:(ManagedLogEntry*)logEntry toDay:(ManagedLogDay*)logDay
{
    logEntry.logDay = logDay;
}

#pragma mark -
#pragma mark Accessors

- (NSArray*) categories
{
    if( !_categories )
    {
	NSError* error = nil;
	_categories = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:[LogModel fetchRequestForOrderedCategoriesInContext:self.managedObjectContext]
											      error:&error]];
    }

    return _categories;
}

- (NSArray*) insulinTypes
{
    if( !_insulinTypes )
    {
	NSError* error = nil;
	_insulinTypes = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:[LogModel fetchRequestForOrderedInsulinTypesInContext:self.managedObjectContext]
												error:&error]];
    }

    return _insulinTypes;
}

- (NSArray*) insulinTypesForNewEntries
{
    if( !_insulinTypesForNewEntries )
    {
	_insulinTypesForNewEntries = [NSMutableArray new];
	for( NSURL* insulinTypeURI in [defaults objectForKey:kDefaultInsulinTypes] )
	{
	    NSManagedObjectID* managedObjectID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:insulinTypeURI];
	    if( managedObjectID )
		[_insulinTypesForNewEntries addObject:[self.managedObjectContext objectWithID:managedObjectID]];
	}
    }

    return _insulinTypesForNewEntries;
}

- (NSArray*) logDays
{
    if( !_logDays )
    {
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"LogDay" inManagedObjectContext:self.managedObjectContext];
	NSError* error = nil;
	_logDays = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    }
    return _logDays;
}

#pragma mark Core Data

+ (void) importFromBundledDatabaseIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    sqlite3* database = [LogModel openDatabasePath:[LogModel bundledDatabasePath]];
    if( !database )
	return;

    NSArray* bundledCategories = [LogModel loadCategoriesFromDatabase:database];
    NSArray* bundledInsulinTypes = [LogModel loadInsulinTypesFromDatabase:database];

    [LogModel closeDatabase:database];

    unsigned index = 0;
    for( Category* category in bundledCategories )
    {
	ManagedCategory* managedCategory = [LogModel insertManagedCategoryIntoContext:managedObjectContext];
	managedCategory.name = category.categoryName;
	managedCategory.sequenceNumber = index;
	++index;
    }

    index = 0;
    for( InsulinType* insulinType in bundledInsulinTypes )
    {
	ManagedInsulinType* managedInsulinType = [LogModel insertManagedInsulinTypeIntoContext:managedObjectContext];
	managedInsulinType.shortName = insulinType.shortName;
	managedInsulinType.sequenceNumber = index;
	++index;
    }
}

- (NSManagedObjectContext*) managedObjectContext
{
    if( !_managedObjectContext )
    {
	BOOL sqliteDatabaseAlreadyExisted = [[NSFileManager defaultManager] fileExistsAtPath:[[LogModel sqlitePersistentStoreURL] path]];
	NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
	if( coordinator )
	{
	    _managedObjectContext = [[NSManagedObjectContext alloc] init];
	    _managedObjectContext.persistentStoreCoordinator = coordinator;

	    if( !sqliteDatabaseAlreadyExisted )
	    {
		NSManagedObjectContext* importContext = [[NSManagedObjectContext alloc] init];
		importContext.persistentStoreCoordinator = coordinator;
		importContext.undoManager = nil;    // Disable the undo manager so it doesn't store history that we don't care about

		[LogModel importFromBundledDatabaseIntoContext:importContext];

		NSError* error;
		if( ![importContext save:&error] )
		    NSLog(@"Couldn't save after importing bundled database: %@", [error localizedDescription]);
	    }
	}
    }

    return _managedObjectContext;
}

- (NSManagedObjectModel*) managedObjectModel
{
    if( !_managedObjectModel )
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Glucose" withExtension:@"momd"]];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    if( _persistentStoreCoordinator )
        return _persistentStoreCoordinator;

    NSError* error = nil;
    NSURL* storeURL = [LogModel sqlitePersistentStoreURL];
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
						   configuration:nil
							     URL:storeURL
							 options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
							   error:&error] )
    {
        /*
         Replace this implementation with code to handle the error appropriately.

         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.


         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
	 [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
         */

        NSLog(@"Unresolved error %@", error);
        abort();
    }

    return _persistentStoreCoordinator;
}

- (void) commitChanges
{
    [self save];
    self.managedObjectContext.undoManager = nil;
}


- (void) save
{
    if( _managedObjectContext )
    {
	NSError *error;
	if( ![_managedObjectContext save:&error] )
	    NSLog(@"Couldn't save because: %@", [error localizedDescription]);
    }
}

- (void) undo
{
    [self.managedObjectContext rollback];
    self.managedObjectContext.undoManager = nil;
}

#pragma mark - Settings

- (GlucoseUnitsType) glucoseUnitsSetting
{
    NSNumber* glucoseSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsGlucoseUnitsKey];
    if( [glucoseSetting isEqualToNumber:kSettingsGlucoseUnitsValue_mgdL] )
	return kGlucoseUnits_mgdL;
    else if( [glucoseSetting isEqualToNumber:kSettingsGlucoseUnitsValue_mmolL] )
	return kGlucoseUnits_mmolL;
    return kGlucoseUnitsUnknown;
}

- (void) setGlucoseUnitsSetting:(GlucoseUnitsType)units
{
    switch( units )
    {
	case kGlucoseUnits_mgdL:
	    [[NSUserDefaults standardUserDefaults] setObject:kSettingsGlucoseUnitsValue_mgdL forKey:kSettingsGlucoseUnitsKey];
	    break;
	case kGlucoseUnits_mmolL:
	    [[NSUserDefaults standardUserDefaults] setObject:kSettingsGlucoseUnitsValue_mmolL forKey:kSettingsGlucoseUnitsKey];
	    break;
	default:
	    break;
    }
}

- (NSString*) highGlucoseWarningThresholdKey
{
    return (kGlucoseUnits_mgdL == self.glucoseUnitsSetting) ? kSettingsHighGlucoseWarningThresholdKey_mgdL : kSettingsHighGlucoseWarningThresholdKey_mmolL;
}

- (NSString*) lowGlucoseWarningThresholdKey
{
    return (kGlucoseUnits_mgdL == self.glucoseUnitsSetting) ? kSettingsLowGlucoseWarningThresholdKey_mgdL : kSettingsLowGlucoseWarningThresholdKey_mmolL;
}

- (NSNumber*) defaultHighGlucoseWarningThreshold
{
    return (kGlucoseUnits_mgdL == self.glucoseUnitsSetting) ? kDefaultHighGlucoseWarningThreshold_mgdL : kDefaultHighGlucoseWarningThreshold_mmolL;
}

- (NSNumber*) defaultLowGlucoseWarningThreshold
{
    return kDefaultHighGlucoseWarningThreshold_mgdL ? kDefaultLowGlucoseWarningThreshold_mgdL : kDefaultLowGlucoseWarningThreshold_mmolL;
}

- (NSNumber*) glucoseThresholdForKey:(NSString*)key default:(NSNumber*)defaultValue
{
    NSNumber* thresholdSetting = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if( !thresholdSetting )
	thresholdSetting = defaultValue;
    return thresholdSetting;
}

- (NSNumber*) highGlucoseWarningThresholdSetting
{
    return [self glucoseThresholdForKey:[self highGlucoseWarningThresholdKey]
				default:[self defaultHighGlucoseWarningThreshold]];
}

- (NSNumber*) lowGlucoseWarningThresholdSetting
{
    return [self glucoseThresholdForKey:[self lowGlucoseWarningThresholdKey]
				default:[self defaultLowGlucoseWarningThreshold]];
}

#pragma mark Glucose Thresholds

- (float) highGlucoseWarningThreshold
{
    return [[self highGlucoseWarningThresholdSetting] floatValue];
}

- (float) lowGlucoseWarningThreshold
{
    return [[self lowGlucoseWarningThresholdSetting] floatValue];
}

- (void) setHighGlucoseWarningThreshold:(NSNumber*)threshold
{
    [[NSUserDefaults standardUserDefaults] setObject:threshold forKey:[self highGlucoseWarningThresholdKey]];
}

- (void) setLowGlucoseWarningThreshold:(NSNumber*)threshold
{
    [[NSUserDefaults standardUserDefaults] setObject:threshold forKey:[self lowGlucoseWarningThresholdKey]];
}

#pragma mark Glucose Threshold Strings

- (NSString*) highGlucoseWarningThresholdString
{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [formatter stringFromNumber:[self highGlucoseWarningThresholdSetting]];
}

- (NSString*) lowGlucoseWarningThresholdString
{
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [formatter stringFromNumber:[self lowGlucoseWarningThresholdSetting]];
}

@end
