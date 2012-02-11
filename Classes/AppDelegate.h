//
//  AppDelegate.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/27/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

#import "LogViewController.h"

@class Category;
@class InsulinType;
@class LogEntry;
@class LogDay;
@class LogModel;

@class GDataServiceGoogleDocs;

@interface AppDelegate : NSObject <UIApplicationDelegate, LogViewDelegate>
{
    IBOutlet UIWindow *window;
    UINavigationController* navController;

@private
    LogModel*	model;
}

@property (nonatomic, retain)	UIWindow*	window;
@property (nonatomic, retain)	UINavigationController* navController;
@property (nonatomic, readonly) GDataServiceGoogleDocs*	docService;

- (void) appendBundledCategories;
- (void) appendBundledInsulinTypes;
- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to;
- (unsigned) numLogEntriesForInsulinTypeID:(unsigned)typeID;
- (unsigned) numLogEntriesFrom:(NSDate*)from to:(NSDate*)to;
- (unsigned) numRowsForCategoryID:(unsigned)catID;
- (NSDate*) earliestLogEntryDate;
- (unsigned) numLogEntries;

// Google Docs
- (void) setUserCredentialsWithUsername:(NSString*)user password:(NSString*)pass;

@end

extern NSDateFormatter* shortDateFormatter;
extern AppDelegate* appDelegate;

