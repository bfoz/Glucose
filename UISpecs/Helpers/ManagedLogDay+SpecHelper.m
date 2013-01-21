#import "ManagedLogDay+SpecHelper.h"

#import "ManagedLogDay+App.h"
#import "ManagedLogEntry.h"

@implementation ManagedLogDay (SpecHelper)

- (ManagedLogEntry*) insertManagedLogEntryWithGlucose:(NSNumber*)glucose
{
    ManagedLogEntry* logEntry = [self insertManagedLogEntry];
    logEntry.glucose = glucose;

    return logEntry;
}

@end
