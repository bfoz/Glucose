#import <UIKit/UIKit.h>

@class DBAccount;
@class LogModel;

@interface DropboxExportViewController : UITableViewController

- (id) initWithDropboxAccount:(DBAccount*)dropboxAccount dataSource:(LogModel*)logModel;

@end
