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
@class ExportViewController;
@class InsulinTypeViewController;
@class NumberField;
@class PurgeViewController;
@class LogModel;

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : SlidingViewController
{
    id<SettingsViewControllerDelegate>    delegate;
    LogModel*		    model;

    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	defaultInsulinTypeViewController;
    InsulinTypeViewController*	insulinTypeViewController;

    UITableViewCell*	highGlucoseWarningCell;
    UITableViewCell*	lowGlucoseWarningCell;
    NumberField*		highGlucoseWarningField;
    NumberField*		lowGlucoseWarningField;
    NSString*			highGlucoseWarningKey;
    NSString*			lowGlucoseWarningKey;

    ExportViewController*	exportViewController;
    PurgeViewController*	purgeViewController;
}

@property (nonatomic, retain)	id<SettingsViewControllerDelegate>    delegate;
@property (nonatomic, retain) LogModel*				    model;

@end

@protocol SettingsViewControllerDelegate <NSObject>

- (void) settingsViewControllerDidChangeGlucoseUnits;
- (void) settingsViewControllerDidPressBack;

@end
