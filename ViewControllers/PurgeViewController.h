#import <UIKit/UIKit.h>

@class LogModel;

@interface PurgeViewController : UITableViewController <UIAlertViewDelegate>

- (id)initWithDataSource:(LogModel*)model;

@end
