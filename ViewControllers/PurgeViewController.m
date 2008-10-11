//
//  PurgeViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 10/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "PurgeViewController.h"

@implementation PurgeViewController

static AppDelegate *appDelegate = nil;

- (id)initWithStyle:(UITableViewStyle)style
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style])
	{
		self.title = @"Purge Records";
		if( !appDelegate )
			appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

		// purgeStart defaults to the day after the last purge
		//  or the current date if no last purge date is stored
		// !! Don't default to the first LogEntry here to avoid accidentally
		// !!  deleting the entire table
		NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
		purgeStart = [defaults objectForKey:kLastPurgeToDate];
		// If the value exists, add one day and use it. Otherwise, use the current date.
		if( purgeStart )
			purgeStart = [purgeStart addTimeInterval:24*60*60];
		else
			purgeStart = [NSDate date];

		purgeEnd = [NSDate date];
		[purgeStart retain];
		[purgeEnd retain];
    }
    return self;
}

- (void)dealloc
{
	[purgeStart release];
	[purgeEnd release];
    [super dealloc];
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch( section )
	{
		case 0:	return 2;
		case 1: return 1;
	}
    return 0;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    switch( section )
	{
		case 0: return @"Date Range (inclusive)";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if( !cell )
	{
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

	switch( indexPath.section )
	{
		case 0:
		{
			UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, kCellTopOffset*2, 100, 20)];
			label.textAlignment = UITextAlignmentRight;
			switch( indexPath.row )
			{
				case 0:
					// The From field defaults to the day after the end of last purge
					//  or the beginning of the LogEntry table if no last export
					cell.text = @"From";
					label.text = [shortDateFormatter stringFromDate:purgeStart];
					purgeStartField = label;
					purgeStartCell = cell;
					break;
				case 1:
					// The To field defaults to Today
					cell.text = @"To";
					label.text = @"Today";
					purgeEndField = label;
					purgeEndCell = cell;
					break;
			}
			cell.accessoryView = label;
		}
		break;
		case 1:
		{
			cell.text = @"Purge";
			cell.textAlignment = UITextAlignmentCenter;
		}
		break;
	}
	return cell;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch( indexPath.section )
	{
		case 0:
			switch( indexPath.row )
			{
				case 0: [self toggleDatePicker:purgeStartCell mode:UIDatePickerModeDate initialDate:purgeStart changeAction:@selector(purgeStartChangeAction)]; break;
				case 1: [self toggleDatePicker:purgeEndCell mode:UIDatePickerModeDate initialDate:purgeEnd changeAction:@selector(purgeEndChangeAction)]; break;
			}
			break;
		case 1:
		{
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Purge %u Records?", [appDelegate numLogEntriesFrom:purgeStart to:purgeEnd]]
															message:[NSString stringWithFormat:@"Delete all records from %@ to %@?", [shortDateFormatter stringFromDate:purgeStart], [shortDateFormatter stringFromDate:purgeEnd]]
														    delegate:self
												   cancelButtonTitle:@"Cancel"
												   otherButtonTitles:@"OK",nil];
			[alert show];
			[alert release];
		}
		break;
	}
}

- (CGFloat) tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
	return (1 == section) ? 40 : 0;
}

- (UIView*) tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
	if( 1 == section )
	{
		NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
		NSDate *const lastPurgeStart = [defaults objectForKey:kLastPurgeFromDate];
		NSDate *const lastPurgeEnd = [defaults objectForKey:kLastPurgeToDate];
		NSDate *const lastPurgedOn = [defaults objectForKey:kLastPurgedOnDate];

		if( lastPurgeStart && lastPurgeEnd && lastPurgedOn )
		{
			UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
			label.text = [NSString stringWithFormat:@"Last purged from %@ to %@ on %@", [shortDateFormatter stringFromDate:purgeStart], [shortDateFormatter stringFromDate:purgeEnd], [shortDateFormatter stringFromDate:lastPurgedOn]];
			label.textAlignment = UITextAlignmentCenter;
			label.backgroundColor = [UIColor clearColor];
			label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];;
			return label;
		}
	}
	return nil;
}

#pragma mark -
#pragma mark <UIAlertViewDelegate>

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( 0 == buttonIndex )	// Nothing to do if Cancel was clicked
		return;

	[appDelegate deleteLogEntriesFrom:purgeStart to:purgeEnd];

	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:purgeStart forKey:kLastPurgeFromDate];
	[defaults setObject:purgeEnd forKey:kLastPurgeToDate];
	[defaults setObject:[NSDate date] forKey:kLastPurgedOnDate];

	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Purge Complete", [appDelegate numLogEntriesFrom:purgeStart to:purgeEnd]]
													message:nil
												   delegate:nil
										  cancelButtonTitle:nil
										  otherButtonTitles:@"OK",nil];
	[alert show];
	[alert release];
}

#pragma mark -
#pragma mark Date/Time Picker

- (void) purgeStartChangeAction
{
	[purgeStart release];
	purgeStart = datePicker.date;
	[purgeStart retain];
	purgeStartField.text = [shortDateFormatter stringFromDate:purgeStart];
}

- (void) purgeEndChangeAction
{
	[purgeEnd release];
	purgeEnd = datePicker.date;
	[purgeEnd retain];
	purgeEndField.text = [shortDateFormatter stringFromDate:purgeEnd];
}


@end

