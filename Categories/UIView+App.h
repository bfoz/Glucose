#import <UIKit/UIKit.h>

@interface UIView (App)

- (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

@end
