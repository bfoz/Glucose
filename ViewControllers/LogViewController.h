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
    NSDateFormatter *dateFormatter;
//	unsigned	inspectingSectionID;
//	NSMutableDictionary*	inspectingSection;
	SettingsViewController*	settingsViewController;
}


- (id)initWithModel:(LogModel*)model delegate:(id<LogViewDelegate>)delegate;

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section;
- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section setEditing:(BOOL)e isNew:(BOOL)n;
- (void) inspectNewLogEntry:(LogEntry*)entry;

@end

@protocol LogViewDelegate <NSObject>
@end
