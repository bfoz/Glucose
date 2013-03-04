#import <CoreData/CoreData.h>
#import <sqlite3.h>

#import "LogModel.h"
#import "LogModel+CoreData.h"
#import "LogModel+SQLite.h"
#import "LogModel+Migration.h"

#import "ManagedCategory.h"
#import "ManagedInsulinDose.h"
#import "ManagedInsulinType.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"

#import "Constants.h"
#import "Category.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogEntry.h"

#define	kSettingsGlucoseUnitsValue_mgdL		@0
#define	kSettingsGlucoseUnitsValue_mmolL	@1

static NSString* kSettingsGlucoseUnitsKey	= @"SettingsGlucoseUnitsKey";
static NSString* kSettingsHighGlucoseWarningThresholdKey_mgdL	= @"HighGlucoseWarning0";
static NSString* kSettingsHighGlucoseWarningThresholdKey_mmolL	= @"HighGlucoseWarning1";
static NSString* kSettingsLowGlucoseWarningThresholdKey_mgdL	= @"LowGlucoseWarning0";
static NSString* kSettingsLowGlucoseWarningThresholdKey_mmolL	= @"LowGlucoseWarning1";

static NSString* kSettingsNewEntryInsulinTypes	= @"SettingsNewEntryInsulinTypes";

static NSNumber* kDefaultHighGlucoseWarningThreshold_mgdL;
static NSNumber* kDefaultHighGlucoseWarningThreshold_mmolL;
static NSNumber* kDefaultLowGlucoseWarningThreshold_mgdL;
static NSNumber* kDefaultLowGlucoseWarningThreshold_mmolL;

NSString* GlucoseUnitsTypeString_mgdL	= @"mg/dL";
NSString* GlucoseUnitsTypeString_mmolL	= @"mmol/L";

@interface LogModel ()

- (void) clearCategoryNameMaxWidth;
- (void) clearInsulinTypeShortNameMaxWidth;

@end

void configureAverageGlucoseFormatter(NSNumberFormatter* averageGlucoseFormatter)
{
    averageGlucoseFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    averageGlucoseFormatter.maximumFractionDigits = ([LogModel glucoseUnitsSetting] == kGlucoseUnits_mgdL) ? 0 : 1;
    averageGlucoseFormatter.positiveSuffix = [NSString stringWithFormat:@" %@", [LogModel glucoseUnitsSettingString]];
}

@implementation LogModel
{
    NSManagedObjectContext*	    _managedObjectContext;
}

@synthesize categories = _categories;
@synthesize insulinTypes = _insulinTypes;
@synthesize insulinTypesForNewEntries = _insulinTypesForNewEntries;

+ (NSArray*) settingsNewEntryInsulinTypes
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsNewEntryInsulinTypes];
}

+ (void) flushInsulinTypesForNewEntries:(NSOrderedSet*)managedInsulinTypes
{
    NSMutableArray* insulinTypeURIs = [NSMutableArray array];
    for( ManagedInsulinType* managedInsulinType in managedInsulinTypes )
    {
	NSURL* uri = [managedInsulinType.objectID URIRepresentation];
	[insulinTypeURIs addObject:[uri absoluteString]];
    }

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:insulinTypeURIs forKey:kSettingsNewEntryInsulinTypes];
    [userDefaults synchronize];
}

#pragma mark -

- (id) init
{
    self = [super init];
    if( self )
    {
	kDefaultHighGlucoseWarningThreshold_mgdL   = @120;
	kDefaultLowGlucoseWarningThreshold_mgdL    = @80;

	kDefaultHighGlucoseWarningThreshold_mmolL  = @6.6;
	kDefaultLowGlucoseWarningThreshold_mmolL   = @4.4;

	_averageGlucoseFormatter = [[NSNumberFormatter alloc] init];
	configureAverageGlucoseFormatter(_averageGlucoseFormatter);

	defaults = [NSUserDefaults standardUserDefaults];
	insulinTypeShortNameMaxWidth = NULL;
	shortDateFormatter = [[NSDateFormatter alloc] init];
	[shortDateFormatter setDateStyle:NSDateFormatterShortStyle];

	[defaults addObserver:self forKeyPath:kSettingsGlucoseUnitsKey options:0 context:nil];
    }

    return self;
}

- (void) dealloc
{
    [defaults removeObserver:self forKeyPath:kSettingsGlucoseUnitsKey];

    _managedObjectContext = nil;
}

#pragma mark - Key Value Observing

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString:kSettingsGlucoseUnitsKey] )
	configureAverageGlucoseFormatter(_averageGlucoseFormatter);
}

#pragma mark -

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
	    [columns addObject:[numberFormatter stringFromNumber:insulinDose.quantity]];
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

    [self save];
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

    [self save];
}

#pragma mark
#pragma mark Insulin Types for New Entries

- (void) addInsulinTypeForNewEntries:(ManagedInsulinType*)type
{
    [self.insulinTypesForNewEntries addObject:type];
    [self flushInsulinTypesForNewEntries];
}

- (void) flushInsulinTypesForNewEntries
{
    [_insulinTypesForNewEntries sortUsingComparator:^(id left, id right) {
	unsigned a = [self.insulinTypes indexOfObjectIdenticalTo:left];
	unsigned b = [self.insulinTypes indexOfObjectIdenticalTo:right];
	if( a < b )
	    return NSOrderedAscending;
	if( a == b )
	    return NSOrderedSame;
	return NSOrderedDescending;
    }];

    [LogModel flushInsulinTypesForNewEntries:_insulinTypesForNewEntries];
}

- (void) removeInsulinTypeForNewEntries:(ManagedInsulinType*)type
{
    if( [self.insulinTypesForNewEntries containsObject:type] )
    {
	[self.insulinTypesForNewEntries removeObject:type];
	[self flushInsulinTypesForNewEntries];
    }
}

- (void) removeInsulinTypeForNewEntriesAtIndex:(unsigned)index
{
    [self.insulinTypesForNewEntries removeObjectAtIndex:index];
    [self flushInsulinTypesForNewEntries];
}

#pragma mark Log Days

+ (ManagedLogDay*) insertManagedLogDayIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"LogDay"
					 inManagedObjectContext:managedObjectContext];
}

static const unsigned DATE_COMPONENTS_FOR_DAY = (NSYearCalendarUnit |
						 NSMonthCalendarUnit |
						 NSDayCalendarUnit);

- (ManagedLogDay*) logDayForDate:(NSDate*)date
{
    NSCalendar* calendar = [NSCalendar currentCalendar];

    NSDateComponents* startDateComponents = [calendar components:DATE_COMPONENTS_FOR_DAY fromDate:date];
    NSDate* startDate = [calendar dateFromComponents:startDateComponents];

    NSDateComponents* offsetComponents = [[NSDateComponents alloc] init];
    offsetComponents.day = 1;
    NSDate* endDate = [calendar dateByAddingComponents:offsetComponents toDate:startDate options:0];

    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogDay"];
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = [NSPredicate predicateWithFormat: @"(date >= %@) && (date < %@)", startDate, endDate];

    NSError* error = nil;
    NSArray* fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if( fetchedObjects.count )
	return [fetchedObjects objectAtIndex:0];

    ManagedLogDay* managedLogDay = [LogModel insertManagedLogDayIntoContext:self.managedObjectContext];
    managedLogDay.date = startDate;

    return managedLogDay;
}

- (unsigned) numberOfLogDays
{
    return [self.managedObjectContext countForFetchRequest:[LogModel fetchRequestForOrderedLogDays] error:nil];
}

#pragma mark Log Entries

- (NSDate*) dateOfEarliestLogEntry
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogEntry"];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES]];
    fetchRequest.fetchLimit = 1;

    NSArray* fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if( fetchedObjects.count )
	return [fetchedObjects objectAtIndex:0];
    return nil;
}

- (unsigned) numberOfLogEntriesFromDate:(NSDate*)startDate toDate:(NSDate*)endDate
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogEntry"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(timestamp >= %@) AND (timestamp <= %@)", startDate, endDate];

    return [self.managedObjectContext countForFetchRequest:fetchRequest error:nil];
}

- (ManagedLogEntry*) insertManagedLogEntry
{
    ManagedLogEntry* managedLogEntry = [ManagedLogEntry insertManagedLogEntryInContext:self.managedObjectContext];
    managedLogEntry.timestamp = [NSDate date];
    managedLogEntry.glucoseUnits = [NSNumber numberWithInt:[LogModel glucoseUnitsSetting]];

    return managedLogEntry;
}

- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogDay"];
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = [NSPredicate predicateWithFormat: @"(date >= %@) && (date <= %@)", from, to];

    NSError* error = nil;
    NSArray* fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for( ManagedLogDay* logDay in fetchedObjects )
	[self.managedObjectContext deleteObject:logDay];
}

- (void) deleteLogEntry:(ManagedLogEntry*)logEntry fromDay:(ManagedLogDay*)logDay
{
    if( 1 == logDay.logEntries.count )	// If the section is about to be empty, delete it
	[self.managedObjectContext deleteObject:logDay];
    else
	[self.managedObjectContext deleteObject:logEntry];
}

#pragma mark -
#pragma mark Accessors

- (NSArray*) categories
{
    if( !_categories )
	_categories = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:[LogModel fetchRequestForOrderedCategoriesInContext:self.managedObjectContext]
											      error:nil]];
    return _categories;
}

- (NSArray*) insulinTypes
{
    if( !_insulinTypes )
	_insulinTypes = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:[LogModel fetchRequestForOrderedInsulinTypesInContext:self.managedObjectContext]
												error:nil]];
    return _insulinTypes;
}

- (NSOrderedSet*) insulinTypesForNewEntries
{
    if( !_insulinTypesForNewEntries )
    {
	_insulinTypesForNewEntries = [[NSMutableOrderedSet alloc] init];
	for( NSString* insulinTypeURIString in [LogModel settingsNewEntryInsulinTypes] )
	{
	    NSManagedObjectID* managedObjectID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:insulinTypeURIString]];
	    if( managedObjectID )
		[_insulinTypesForNewEntries addObject:[self.managedObjectContext objectWithID:managedObjectID]];
	}
    }

    return _insulinTypesForNewEntries;
}

#pragma mark Core Data

- (NSFetchRequest*) fetchRequestForOrderedLogEntries
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LogEntry"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"logDay.date" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];

    return fetchRequest;
}

- (NSManagedObjectContext*) managedObjectContext
{
    if( !_managedObjectContext )
	_managedObjectContext = [LogModel managedObjectContext];

    return _managedObjectContext;
}

- (void) commitChanges
{
    [self save];
    self.managedObjectContext.undoManager = nil;
}


- (void) save
{
    if( _managedObjectContext )
	[LogModel saveManagedObjectContext:_managedObjectContext];
}

- (void) undo
{
    [self.managedObjectContext rollback];
    self.managedObjectContext.undoManager = nil;
}

#pragma mark - Settings

+ (GlucoseUnitsType) glucoseUnitsSetting
{
    NSNumber* glucoseSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsGlucoseUnitsKey];
    if( [glucoseSetting isEqualToNumber:kSettingsGlucoseUnitsValue_mgdL] )
	return kGlucoseUnits_mgdL;
    else if( [glucoseSetting isEqualToNumber:kSettingsGlucoseUnitsValue_mmolL] )
	return kGlucoseUnits_mmolL;
    return kGlucoseUnits_mgdL;
}

+ (NSString*) glucoseUnitsSettingString
{
    if( kGlucoseUnits_mgdL == [self glucoseUnitsSetting] )
	return GlucoseUnitsTypeString_mgdL;
    else
	return GlucoseUnitsTypeString_mmolL;
}

+ (void) setGlucoseUnitsSetting:(GlucoseUnitsType)units
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

- (unsigned) glucosePrecisionForNewEntries
{
    return ([LogModel glucoseUnitsSetting] == kGlucoseUnits_mgdL) ? 0 : 1;
}

- (NSString*) highGlucoseWarningThresholdKey
{
    return (kGlucoseUnits_mgdL == [LogModel glucoseUnitsSetting]) ? kSettingsHighGlucoseWarningThresholdKey_mgdL : kSettingsHighGlucoseWarningThresholdKey_mmolL;
}

- (NSString*) lowGlucoseWarningThresholdKey
{
    return (kGlucoseUnits_mgdL == [LogModel glucoseUnitsSetting]) ? kSettingsLowGlucoseWarningThresholdKey_mgdL : kSettingsLowGlucoseWarningThresholdKey_mmolL;
}

- (NSNumber*) defaultHighGlucoseWarningThreshold
{
    return (kGlucoseUnits_mgdL == [LogModel glucoseUnitsSetting]) ? kDefaultHighGlucoseWarningThreshold_mgdL : kDefaultHighGlucoseWarningThreshold_mmolL;
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
