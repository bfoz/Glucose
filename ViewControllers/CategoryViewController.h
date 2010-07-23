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

@class	Category;
@protocol CategoryViewControllerDelegate;

@interface CategoryViewController : SlidingViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    id <CategoryViewControllerDelegate>	delegate;
	BOOL			dirty;
    unsigned	deleteRowNum;
    Category*	selectedCategory;
}

@property (nonatomic, assign) id <CategoryViewControllerDelegate>   delegate;
@property (nonatomic, assign) id selectedCategory;

@end

@protocol CategoryViewControllerDelegate <NSObject>

@optional
- (void) categoryViewControllerDidSelectCategory:(Category*)category;

@end
