
#import <sqlite3.h>

@class InsulinType;
@class LogEntry;
@class LogDay;
@class LogModel;

@interface AppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) LogModel*	model;
@property (nonatomic, strong, readonly) UINavigationController*	navigationController;

@end

extern NSDateFormatter* shortDateFormatter;
extern AppDelegate* appDelegate;

