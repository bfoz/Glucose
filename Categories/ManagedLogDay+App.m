#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"

@implementation ManagedLogDay (App)

- (ManagedLogEntry*) insertManagedLogEntry
{
    ManagedLogEntry* logEntry = [ManagedLogEntry insertManagedLogEntryInContext:self.managedObjectContext];
    logEntry.logDay = self;
    return logEntry;
}

- (NSString*) dateString
{
    NSDateFormatter *const shortDateFormatter = [[NSDateFormatter alloc] init];
    [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
    return [shortDateFormatter stringFromDate:self.date];
}

- (void) updateStatistics
{
    self.averageGlucose = [self valueForKeyPath:@"logEntries.@avg.glucose"];
    self.averageGlucoseString = NULL;
}

- (NSString*) titleForHeader
{
    NSString *const average = self.averageGlucoseString;

    // Don't display the average if it's zero
    if( average )
	return [NSString stringWithFormat:@"%@ (%@)", self.dateString, average, nil];
    else
	return [NSString stringWithFormat:@"%@", self.dateString, nil];
}

@end
