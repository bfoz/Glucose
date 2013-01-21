#import "LogModel.h"

@interface LogModel (Migration)

+ (NSString*) backupPath;
+ (void) migrateTheDatabase;
+ (BOOL) needsMigration;

@end
