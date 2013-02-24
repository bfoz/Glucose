//
//  NumberFieldCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 1/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberField.h"

@class ManagedLogEntry;

@protocol NumberFieldCellDelegate;

@interface NumberFieldCell : UITableViewCell <UITextFieldDelegate>
{
    NumberField*    field;
}

@property (nonatomic, weak) id <NumberFieldCellDelegate> delegate;

@property (nonatomic, readonly)	UITextField*	field;
@property (nonatomic, copy)	NSNumber*	number;
@property (nonatomic, copy)	NSString*	labelText;

@property (nonatomic)	UITextFieldViewMode	clearButtonMode;
@property (nonatomic, strong)	UIFont*	font;
@property (nonatomic, copy)	NSString*	placeholder;
@property (nonatomic, assign)	int	precision;
@property (nonatomic)	UITextAlignment	textAlignment;

+ (NumberFieldCell*) cellForLogEntry:(ManagedLogEntry*)logEntry accessoryView:(UIView*)accessoryView delegate:(id<NumberFieldCellDelegate>)delegate tableView:(UITableView*)tableView;
+ (NumberFieldCell*) cellForNumber:(NSNumber*)number precision:(int)precision unitsString:(NSString*)unitsString inputAccessoryView:(UIView*)inputAccessoryView delegate:(id<NumberFieldCellDelegate>)delegate tableView:(UITableView*)tableView;

- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

@end

@protocol NumberFieldCellDelegate <NSObject>

@optional
- (BOOL)numberFieldCellShouldBeginEditing:(NumberFieldCell*)cell;
- (void)numberFieldCellDidBeginEditing:(NumberFieldCell*)cell;
- (void)numberFieldCellDidEndEditing:(NumberFieldCell*)cell;

@end
