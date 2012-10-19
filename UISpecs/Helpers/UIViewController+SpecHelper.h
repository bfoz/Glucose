#import <UIKit/UIKit.h>

@interface UIViewController (SpecHelper)
@property (nonatomic, retain) UIViewController *modalViewController;
@property (nonatomic, assign) UIViewController *presentingViewController;
@end
