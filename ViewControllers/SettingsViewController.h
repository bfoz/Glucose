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

@interface SettingsViewController : SlidingViewController <UITextFieldDelegate>
{
    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	defaultInsulinTypeViewController;
    InsulinTypeViewController*	insulinTypeViewController;

    UITableViewCell*	highGlucoseWarningCell;
    UITableViewCell*	lowGlucoseWarningCell;
    UITextField*		highGlucoseWarningField;
    UITextField*		lowGlucoseWarningField;
    NSString*			highGlucoseWarningKey;
    NSString*			lowGlucoseWarningKey;

    UITableViewController*	exportViewController;
    UITableViewController*	purgeViewController;
}

@end
