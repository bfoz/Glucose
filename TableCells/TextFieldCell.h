//
//  TextFieldCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "EditableTableViewCell.h"

@protocol TextFieldCellDelegate;

//@interface TextFieldCell : EditableTableViewCell <UITextFieldDelegate>
@interface TextFieldCell : UITableViewCell <UITextFieldDelegate>
{
	id <TextFieldCellDelegate> __unsafe_unretained delegate;
	id __unsafe_unretained editedObject;
    UITextField *view;
}

@property (nonatomic)	UITextFieldViewMode	clearButtonMode;
@property (nonatomic, unsafe_unretained)	id	<TextFieldCellDelegate>	delegate;
@property (nonatomic, unsafe_unretained)	id	editedObject;
@property (nonatomic, strong)	UIFont*	font;
@property (nonatomic, copy)	NSString*	placeholder;
@property (nonatomic, copy)	NSString*	text;
@property (unsafe_unretained, nonatomic, readonly) UITextField*	textField;
@property (nonatomic)	UITextAlignment	textAlignment;
@property (nonatomic, strong) UITextField *view;

- (void) resignFirstResponder;

@end

@protocol TextFieldCellDelegate <NSObject>

@optional
- (BOOL)textFieldCellShouldBeginEditing:(TextFieldCell*)cell;
- (void)textFieldCellDidBeginEditing:(TextFieldCell*)cell;
- (void)textFieldCellDidEndEditing:(TextFieldCell*)cell;

@end
