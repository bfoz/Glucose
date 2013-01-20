#import "LogModel.h"

@interface LogModel (Migration)

+ (NSString*) backupPath;
+ (void) checkForMigration;
+ (BOOL) needsMigration;

@end
