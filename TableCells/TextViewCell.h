#import <UIKit/UIKit.h>

@class ManagedLogEntry;

@protocol TextViewCellDelegate;

@interface TextViewCell : UITableViewCell <UITextViewDelegate>

@property (nonatomic, unsafe_unretained) id <TextViewCellDelegate> delegate;
@property (nonatomic, assign)	BOOL	dirty;
@property (nonatomic, strong)	UIFont*	font;
@property (nonatomic, copy) NSString*	    placeholder;
@property (nonatomic, copy) NSString*	    text;
@property (nonatomic, readonly) UITextView* textView;

+ (TextViewCell*) cellForLogEntry:(ManagedLogEntry*)logEntry delegate:(id<TextViewCellDelegate>)delegate inputAccessoryView:(UIView*)inputAccessoryView tableView:(UITableView*)tableView;

@end

@protocol TextViewCellDelegate <NSObject>

@optional
- (BOOL)textViewCellShouldBeginEditing:(TextViewCell*)cell;
- (void)textViewCellDidBeginEditing:(TextViewCell*)cell;
- (void)textViewCellDidEndEditing:(TextViewCell*)cell;

@end
