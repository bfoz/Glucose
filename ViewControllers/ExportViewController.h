#import <UIKit/UIKit.h>

@class LogModel;

@interface ExportViewController : UITableViewController

- (id)initWithDataSource:(LogModel*)model;

@end
