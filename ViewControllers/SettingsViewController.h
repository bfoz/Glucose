//
//  SettingsViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingViewController.h"

@class CategoryViewController;
@class InsulinTypeViewController;

//@interface SettingsViewController : UITableViewController
@interface SettingsViewController : SlidingViewController
{
	CategoryViewController*	categoryViewController;
	InsulinTypeViewController*	insulinTypeViewController;
	
	UITableViewCell*	highGlucoseWarningCell;
	UITableViewCell*	lowGlucoseWarningCell;
//	UITextField*		editField;
	UITextField*		highGlucoseWarningField;
	UITextField*		lowGlucoseWarningField;
}

@end
