//
//  PurgeViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 10/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SlidingViewController.h"

@class LogModel;

@interface PurgeViewController : SlidingViewController <UIAlertViewDelegate>
{
	NSDate*	purgeStart;
	NSDate*	purgeEnd;
	BOOL	purgeEnabled;

	UITableViewCell*	purgeCell;
	UILabel*			purgeStartField;
	UILabel*			purgeEndField;
	UITableViewCell*	purgeStartCell;
	UITableViewCell*	purgeEndCell;

@private
    LogModel*			model;
}

@property (nonatomic, retain) LogModel*	model;

@end
