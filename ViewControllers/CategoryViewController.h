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

@class AppDelegate;

//@interface CategoryViewController : UITableViewController <TextViewCellDelegate, UIAlertViewDelegate>
@interface CategoryViewController : SlidingViewController <TextFieldCellDelegate>
{
	AppDelegate*	appDelegate;
    id				editedObject;
	BOOL			dirty;
}

@property (nonatomic, retain) id editedObject;

@end
