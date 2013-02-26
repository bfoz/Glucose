#import <UIKit/UIKit.h>

@protocol EditTextViewControllerDelegate <NSObject>
- (void) editTextViewControllerDidFinishWithText:(NSString*)text;
@end

@interface EditTextViewController : UIViewController

@property (nonatomic, strong) id<EditTextViewControllerDelegate>    delegate;

- (id)initWithText:(NSString*)text;

- (NSString*) text;

@end
