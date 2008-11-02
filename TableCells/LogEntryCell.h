//
//  LogEntryCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 8/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LogEntry;

@interface LogEntryCell : UITableViewCell
{
//	LogEntry* entry;

// Private
	UILabel*	labelCategory;
	UILabel*	labelDose0;
	UILabel*	labelDose1;
	UILabel*	labelGlucose;
	UILabel*	labelNote;
	UILabel*	labelTimestamp;
	UILabel*	labelType0;
	UILabel*	labelType1;
}

//@property (nonatomic, retain) LogEntry* entry;

@property (nonatomic, readonly)	UILabel*	labelCategory;
@property (nonatomic, readonly)	UILabel*	labelDose0;
@property (nonatomic, readonly)	UILabel*	labelDose1;
@property (nonatomic, readonly)	UILabel*	labelGlucose;
@property (nonatomic, readonly)	UILabel*	labelTimestamp;
@property (nonatomic, readonly)	UILabel*	labelType0;
@property (nonatomic, readonly)	UILabel*	labelType1;

// Virtual properties
@property (nonatomic, copy)	NSString*	note;

@end
