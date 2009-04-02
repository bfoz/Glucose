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
	id <TextFieldCellDelegate> delegate;
	id editedObject;
    UITextField *view;
}

@property (nonatomic)	UITextFieldViewMode	clearButtonMode;
@property (nonatomic, assign)	id	<TextFieldCellDelegate>	delegate;
@property (nonatomic, assign)	id	editedObject;
@property (nonatomic, retain)	UIFont*	font;
@property (nonatomic, copy)	NSString*	placeholder;
@property (nonatomic, copy)	NSString*	text;
@property (nonatomic)	UITextAlignment	textAlignment;
@property (nonatomic, retain) UITextField *view;

- (void) resignFirstResponder;

@end

@protocol TextFieldCellDelegate <NSObject>

@optional
- (BOOL)textFieldCellShouldBeginEditing:(TextFieldCell*)cell;
- (void)textFieldCellDidBeginEditing:(TextFieldCell*)cell;
- (void)textFieldCellDidEndEditing:(TextFieldCell*)cell;

@end
