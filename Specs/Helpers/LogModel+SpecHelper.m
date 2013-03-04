#import <CoreData/CoreData.h>

#import "LogModel+CoreData.h"
#import "LogModel+SpecHelper.h"

#import "ManagedInsulinType.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"

@interface LogModel ()
- (NSManagedObjectContext*) managedObjectContext;
@end

@implementation LogModel (SpecHelper)

+ (void) afterEach
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* domain = [[NSBundle mainBundle] bundleIdentifier];
    [defaults removePersistentDomainForName:domain];
    for( NSString* key in [defaults persistentDomainForName:domain] )
	[defaults removeObjectForKey:key];
    [NSUserDefaults resetStandardUserDefaults];
}

#pragma mark Core Data Helpers

- (ManagedInsulinType*) insertManagedInsulinType
{
    return [LogModel insertManagedInsulinTypeIntoContext:self.managedObjectContext];
}

- (ManagedInsulinType*) insertManagedInsulinTypeShortName:(NSString*)name
{
    ManagedInsulinType* managedInsulinType =  [self insertManagedInsulinType];
    managedInsulinType.shortName = name;

    return managedInsulinType;
}

- (ManagedLogDay*) insertManagedLogDay
{
    ManagedLogDay* logDay = [LogModel insertManagedLogDayIntoContext:self.managedObjectContext];
    [(NSMutableArray*)self.logDays addObject:logDay];
    return logDay;
}

- (ManagedLogEntry*) insertManagedLogEntryIntoManagedLogDay:(ManagedLogDay*)logDay
{
    ManagedLogEntry* logEntry = [logDay insertManagedLogEntry];
    logEntry.timestamp = [NSDate date];
    logEntry.glucoseUnits = [NSNumber numberWithInt:[LogModel glucoseUnitsSetting]];

    return logEntry;
}

@end
