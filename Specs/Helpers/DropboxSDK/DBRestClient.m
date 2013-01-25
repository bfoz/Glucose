#import "DBRestClient.h"

@implementation DBRestClient

- (id) initWithSession:(DBSession*)session
{
    return [super init];
}

- (void) uploadFile:(NSString *)filename toPath:(NSString *)path withParentRev:(NSString *)parentRev
	  fromPath:(NSString *)sourcePath
{
}

@end
