#import "DBSession.h"

DBSession* _sharedSession = nil;

@implementation DBSession

+ (DBSession*) sharedSession
{
    if( !_sharedSession )
	_sharedSession = [[DBSession alloc] init];
    return _sharedSession;
}

- (void) unlinkUserId:(NSString*)userID
{
}

@end
