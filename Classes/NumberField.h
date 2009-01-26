//
//  NumberField.h
//  Glucose
//
//  Created by Brandon Fosdick on 1/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NumberField : UITextField
{
    NSMutableString*	input;
    int	precision;
}

@property (nonatomic, copy)	NSNumber*	number;
@property (nonatomic, assign)	int	precision;

- (BOOL) hasNumber;

@end
