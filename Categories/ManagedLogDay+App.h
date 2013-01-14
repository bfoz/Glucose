#import "ManagedLogDay.h"

@interface ManagedLogDay (App)

- (NSString*) dateString;
- (void) updateStatistics;
- (NSString*) titleForHeader;

- (ManagedLogEntry*) insertManagedLogEntry;

@end
