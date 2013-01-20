
#import <sqlite3.h>

@class InsulinType;
@class LogEntry;
@class LogDay;
@class LogModel;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
    IBOutlet UIWindow *window;
    UINavigationController* navController;
}

@property (nonatomic, strong) LogModel*	model;
@property (nonatomic, strong)	UIWindow*	window;
@property (nonatomic, strong)	UINavigationController* navController;

@end

extern NSDateFormatter* shortDateFormatter;
extern AppDelegate* appDelegate;

