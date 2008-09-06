//
//  CategoryViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextFieldCell.h"

@class AppDelegate;

//@interface CategoryViewController : UITableViewController <TextViewCellDelegate, UIAlertViewDelegate>
@interface CategoryViewController : UITableViewController <TextFieldCellDelegate>
{
	AppDelegate*	appDelegate;
    id				editedObject;
	BOOL			dirty;
	TextFieldCell*	editCell;
	CGFloat			keyboardHeight;
	CGFloat			editFieldBottom;
}

@property (nonatomic, retain) id editedObject;

@end
