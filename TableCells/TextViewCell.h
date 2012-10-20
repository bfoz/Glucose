#import <UIKit/UIKit.h>

@protocol TextViewCellDelegate;

@interface TextViewCell : UITableViewCell <UITextViewDelegate>

@property (nonatomic, unsafe_unretained) id <TextViewCellDelegate> delegate;
@property (nonatomic, assign)	BOOL	dirty;
@property (nonatomic, strong)	UIFont*	font;
@property (nonatomic, copy) NSString*	    placeholder;
@property (nonatomic, copy) NSString*	    text;
@property (nonatomic, readonly) UITextView* textView;

@end

@protocol TextViewCellDelegate <NSObject>

@optional
- (BOOL)textViewCellShouldBeginEditing:(TextViewCell*)cell;
- (void)textViewCellDidBeginEditing:(TextViewCell*)cell;
- (void)textViewCellDidEndEditing:(TextViewCell*)cell;

@end
