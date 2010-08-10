//
//  LogViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LogEntry.h"
#import "LogEntryViewController.h"

@class SettingsViewController;

@interface LogViewController : UITableViewController
{
    NSDateFormatter *dateFormatter;
//	unsigned	inspectingSectionID;
//	NSMutableDictionary*	inspectingSection;
	LogEntryViewController* logEntryViewController;
	SettingsViewController*	settingsViewController;
}
@property (nonatomic, retain) LogEntryViewController* logEntryViewController;

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section;
- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section setEditing:(BOOL)e isNew:(BOOL)n;

@end
