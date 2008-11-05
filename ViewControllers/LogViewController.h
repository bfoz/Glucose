//
//  LogViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// Import the AppDelegate because it owns the entries array
#import "AppDelegate.h"
#import "LogEntry.h"
#import "LogEntryViewController.h"

@class SettingsViewController;

@interface LogViewController : UITableViewController
{
	AppDelegate* appDelegate;
    NSDateFormatter *dateFormatter;
    NSNumberFormatter*	glucoseFormatter;
//	unsigned	inspectingSectionID;
//	NSMutableDictionary*	inspectingSection;
	LogEntryViewController* logEntryViewController;
	SettingsViewController*	settingsViewController;
}
//@property (nonatomic, retain) AppDelegate* appDelegate;
@property (nonatomic, retain) LogEntryViewController* logEntryViewController;

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section;
- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section setEditing:(BOOL)e;

@end
