//
//  SettingsViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>
#import "SlidingViewController.h"

@class CategoryViewController;
@class InsulinTypeViewController;

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : SlidingViewController <CategoryViewControllerDelegate, InsulinTypeViewControllerDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate>
{
    id<SettingsViewControllerDelegate>    delegate;

    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	defaultInsulinTypeViewController;
    InsulinTypeViewController*	insulinTypeViewController;

    UITableViewCell*	highGlucoseWarningCell;
    UITableViewCell*	lowGlucoseWarningCell;
    NumberField*		highGlucoseWarningField;
    NumberField*		lowGlucoseWarningField;
    NSString*			highGlucoseWarningKey;
    NSString*			lowGlucoseWarningKey;

    UITableViewController*	exportViewController;
    UITableViewController*	purgeViewController;
}

@property (nonatomic, retain)	id<SettingsViewControllerDelegate>    delegate;

@end

@protocol SettingsViewControllerDelegate <NSObject>

- (void) settingsViewControllerDidPressBack;

@end
