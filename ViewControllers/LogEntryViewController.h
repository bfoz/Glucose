//
//  LogEntryViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

#import "DoseFieldCell.h"
#import "TextFieldCell.h"
#import "TextViewCell.h"

@class CategoryViewController;
@class InsulinTypeViewController;
@class LogEntry;

//@interface LogEntryViewController : UITableViewController <DoseFieldCellDelegate, UITextFieldDelegate, TextViewCellDelegate>
@interface LogEntryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, DoseFieldCellDelegate, TextViewCellDelegate, TextFieldCellDelegate>
//@interface LogEntryViewController : UIViewController
{
	LogEntry* entry;
	NSMutableDictionary*	entrySection;

// Private
	CategoryViewController*	categoryViewController;
	InsulinTypeViewController*	insulinTypeViewController;
    NSDateFormatter*	dateFormatter;
	UIDatePicker*	datePicker;
    NSNumberFormatter*	glucoseFormatter;
    NSNumberFormatter*	numberFormatter;
	UITextField*	glucoseTextField;
    UITableView*	tableView;
    NSIndexPath*	selectedIndexPath;
	CGFloat			keyboardHeight;
	CGFloat			editFieldBottom;
	UITableViewCell*	editCell;
	UITableViewCell*	cellTimestamp;
    sqlite3*	database;			// SQLite database handle
}

@property (nonatomic, retain) LogEntry* entry;
@property (nonatomic, retain) NSMutableDictionary* entrySection;

@end
