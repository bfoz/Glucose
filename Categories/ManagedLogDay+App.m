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

- (NSString*) averageGlucoseString
{
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [NSString stringWithFormat:@"%@ %@", [numberFormatter stringFromNumber:self.averageGlucose], [LogModel glucoseUnitsSettingString]];
}

- (NSString*) dateString
{
    NSDateFormatter *const shortDateFormatter = [[NSDateFormatter alloc] init];
    shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
    shortDateFormatter.doesRelativeDateFormatting = YES;
    return [shortDateFormatter stringFromDate:self.date];
}

- (void) updateStatistics
{
    self.averageGlucose = [self valueForKeyPath:@"logEntries.@avg.glucose"];
}

- (NSString*) titleForHeader
{
    // Don't display the average if it's zero
    if( self.averageGlucose && ![self.averageGlucose isEqualToNumber:@0] )
	return [NSString stringWithFormat:@"%@ (%@)", self.dateString, self.averageGlucoseString];
    else
	return [NSString stringWithFormat:@"%@", self.dateString];
}

@end
