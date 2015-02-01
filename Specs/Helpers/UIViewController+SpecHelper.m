#import "UIViewController+SpecHelper.h"
#import <objc/runtime.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UIViewController (SpecHelper)

#pragma mark - Modals
- (void)setPresentingViewController:(UIViewController *)presentingViewController {
    objc_setAssociatedObject(self, "presentingViewController", presentingViewController, OBJC_ASSOCIATION_RETAIN);
}

- (UIViewController *)presentingViewController {
    return objc_getAssociatedObject(self, "presentingViewController");
}


#pragma mark - Animation
- (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    animations();
    completion(YES);
}


@end
