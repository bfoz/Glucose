#import "LogModel.h"

@interface LogModel (Migration)

+ (NSString*) backupPath;
+ (NSDictionary*) migrateTheDatabaseWithProgressView:(UIProgressView*)progressView;
+ (BOOL) needsMigration;

@end
