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
    id <NumberFieldCellDelegate> delegate;

    NumberField*    field;
    UILabel*	_label;
}

@property (nonatomic, assign) id <NumberFieldCellDelegate> delegate;

@property (nonatomic, readonly)	UITextField*	field;
@property (nonatomic, copy)	NSNumber*	number;
@property (nonatomic, copy)	NSString*	label;

@property (nonatomic)	UITextFieldViewMode	clearButtonMode;
@property (nonatomic, retain)	UIFont*	font;
@property (nonatomic, copy)	NSString*	placeholder;
@property (nonatomic, assign)	int	precision;
@property (nonatomic)	UITextAlignment	textAlignment;

- (BOOL) becomeFirstResponder;
- (void) resignFirstResponder;

@end

@protocol NumberFieldCellDelegate <NSObject>

- (BOOL)numberFieldCellShouldBeginEditing:(NumberFieldCell*)cell;
- (void)numberFieldCellDidBeginEditing:(NumberFieldCell*)cell;
- (void)numberFieldCellDidEndEditing:(NumberFieldCell*)cell;

@end
