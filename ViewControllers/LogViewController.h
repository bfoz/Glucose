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

@class LogModel;
@class SettingsViewController;
@protocol LogViewDelegate;

@interface LogViewController : UITableViewController <LogEntryViewDelegate>
{
    id <LogViewDelegate>    delegate;
    LogModel*		    model;

    NSDateFormatter *dateFormatter;
//	unsigned	inspectingSectionID;
//	NSMutableDictionary*	inspectingSection;
	LogEntryViewController* logEntryViewController;
	SettingsViewController*	settingsViewController;
}
@property (nonatomic, assign) id <LogViewDelegate>  delegate;
@property (nonatomic, retain) LogModel*		    model;
@property (nonatomic, retain) LogEntryViewController* logEntryViewController;

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section;
- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section setEditing:(BOOL)e isNew:(BOOL)n;
- (void) inspectNewLogEntry:(LogEntry*)entry;

@end

@protocol LogViewDelegate <NSObject>
@end
