#import "LogModel.h"

@interface LogModel (Migration)

+ (NSString*) backupPath;
+ (void) migrateTheDatabaseWithProgressView:(UIProgressView*)progressView;
+ (BOOL) needsMigration;

@end
