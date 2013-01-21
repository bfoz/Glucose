#import "ManagedLogDay.h"

@class ManagedLogEntry;

@interface ManagedLogDay (SpecHelper)

- (ManagedLogEntry*) insertManagedLogEntryWithGlucose:(NSNumber*)glucose;

@end
