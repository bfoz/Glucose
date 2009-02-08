//
//  DoseFieldCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InsulinDose.h"
#import "NumberField.h"

@protocol DoseFieldCellDelegate;

@interface DoseFieldCell : UITableViewCell <UITextFieldDelegate>
{
    id <DoseFieldCellDelegate> delegate;
    InsulinDose* dose;
    NumberField* doseField;
    UILabel* typeField;
}

@property (nonatomic, assign) id <DoseFieldCellDelegate> delegate;
@property (nonatomic, retain) InsulinDose* dose;
@property (nonatomic, readonly) NumberField* doseField;
@property (nonatomic, assign) int   precision;

@end

@protocol DoseFieldCellDelegate <NSObject>

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)doseShouldBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidEndEditing:(DoseFieldCell *)cell;

@end
