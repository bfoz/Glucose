#import <Foundation/Foundation.h>

@interface DBSession : NSObject

+ (DBSession*) sharedSession;

- (void) unlinkUserId:(NSString*)userID;

@end
