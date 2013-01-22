#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"

#import "LogModel.h"

@implementation ManagedLogDay (App)

- (ManagedLogEntry*) insertManagedLogEntry
{
    ManagedLogEntry* logEntry = [ManagedLogEntry insertManagedLogEntryInContext:self.managedObjectContext];
    logEntry.logDay = self;
    return logEntry;
}

#pragma mark -

- (void) updateStatistics
{
    self.averageGlucose = [self valueForKeyPath:@"logEntries.@avg.glucose"];
}

@end
