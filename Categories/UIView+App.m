#import "UIView+App.h"

@implementation UIView (App)

- (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:duration animations:animations completion:completion];
}

@end
