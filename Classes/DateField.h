#import <UIKit/UIKit.h>

@class DateField;

@protocol DateFieldDelegate <UITextFieldDelegate>
- (void) dateFieldDidChangeValue:(DateField*)dateField;
- (void) dateFieldWillCancelEditing:(DateField*)dateField;
@end

@interface DateField : UITextField

@property (nonatomic, strong) NSDate*	date;
@property (nonatomic, unsafe_unretained) id<DateFieldDelegate> delegate;

- (UIToolbar*) toolbar;

@end
