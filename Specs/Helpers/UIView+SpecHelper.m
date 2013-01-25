#import "UIView+SpecHelper.h"

@implementation UIView (SpecHelper)
- (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    animations();
    completion(YES);
}

@end
