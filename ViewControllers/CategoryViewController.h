//
//  CategoryViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SlidingViewController.h"
#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@protocol CategoryViewControllerDelegate;

@interface CategoryViewController : SlidingViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    id <CategoryViewControllerDelegate>	delegate;
    id				editedObject;
	BOOL			dirty;
    unsigned	deleteRowNum;
}

@property (nonatomic, assign) id <CategoryViewControllerDelegate>   delegate;
@property (nonatomic, retain) id editedObject;

@end

@protocol CategoryViewControllerDelegate <NSObject>

@optional
- (void) categoryViewControllerDidSelectCategory:(Category*)category;

@end
