#import <UIKit/UIKit.h>

@class LogModel;

@interface DropboxExportViewController : UITableViewController

- (id) initWithUserID:(NSString*)userID dataSource:(LogModel*)logModel;

@end
