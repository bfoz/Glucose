//
//  NumberFieldCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 1/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberField.h"

@protocol NumberFieldCellDelegate;

@interface NumberFieldCell : UITableViewCell <UITextFieldDelegate>
{
    id <NumberFieldCellDelegate> __unsafe_unretained delegate;

    NumberField*    field;
}

@property (nonatomic, unsafe_unretained) id <NumberFieldCellDelegate> delegate;

@property (nonatomic, readonly)	UITextField*	field;
@property (nonatomic, copy)	NSNumber*	number;
@property (nonatomic, copy)	NSString*	labelText;

@property (nonatomic)	UITextFieldViewMode	clearButtonMode;
@property (nonatomic, strong)	UIFont*	font;
@property (nonatomic, copy)	NSString*	placeholder;
@property (nonatomic, assign)	int	precision;
@property (nonatomic)	UITextAlignment	textAlignment;

- (BOOL) becomeFirstResponder;
- (void) resignFirstResponder;

@end

@protocol NumberFieldCellDelegate <NSObject>

@optional
- (BOOL)numberFieldCellShouldBeginEditing:(NumberFieldCell*)cell;
- (void)numberFieldCellDidBeginEditing:(NumberFieldCell*)cell;
- (void)numberFieldCellDidEndEditing:(NumberFieldCell*)cell;

@end
