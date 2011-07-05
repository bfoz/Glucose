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
@class	LogModel;
@protocol CategoryViewControllerDelegate;

@interface CategoryViewController : SlidingViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    id <CategoryViewControllerDelegate>	delegate;
    LogModel*			model;

    BOOL	didUndo;
	BOOL			dirty;
    Category*	deleteCategory;
    unsigned	deleteRow;
    Category*	selectedCategory;
}

@property (nonatomic, assign) id <CategoryViewControllerDelegate>   delegate;
@property (nonatomic, retain) LogModel*				    model;
@property (nonatomic, assign) id selectedCategory;

@end

@protocol CategoryViewControllerDelegate <NSObject>

@optional
- (void) categoryViewControllerCreateCategory;
- (void) categoryViewControllerDidDeleteCategory:(Category*)category;
- (void) categoryViewControllerDidSelectCategory:(Category*)category;
- (void) categoryViewControllerDidSelectRestoreDefaults;

@end
