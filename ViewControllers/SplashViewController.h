#import <UIKit/UIKit.h>

@protocol SplashViewControllerDelegate <NSObject>
- (void) splashViewControllerDidFinish;
@end

@interface SplashViewController : UIViewController
@property (nonatomic, weak) id<SplashViewControllerDelegate>	delegate;
@property (nonatomic, strong, readonly) UILabel*	textLabel;
@end
