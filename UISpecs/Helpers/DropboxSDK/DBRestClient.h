#import "DBSession.h"

@protocol DBRestClientDelegate;

@interface DBRestClient : NSObject

@property (nonatomic, assign) id<DBRestClientDelegate> delegate;

- (id) initWithSession:(DBSession*)session;

- (void)uploadFile:(NSString *)filename toPath:(NSString *)path withParentRev:(NSString *)parentRev
	  fromPath:(NSString *)sourcePath;

@end
