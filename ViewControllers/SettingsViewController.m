//
//  SettingsViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "CategoryViewController.h"
#import "ExportViewController.h"
#import "InsulinTypeViewController.h"
#import "LogViewController.h"
#import "PurgeViewController.h"
#import "SettingsViewController.h"

@implementation SettingsViewController

//@synthesize categoryViewController;

static AppDelegate* appDelegate = nil;

- (id)initWithStyle:(UITableViewStyle)style
{
	if( self = [super initWithStyle:style] )
	{
		if( !appDelegate )
			appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

		self.navigationItem.hidesBackButton = YES;
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
		self.title = @"Settings";
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

		NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
		const BOOL mgdL = [[defaults objectForKey:kDefaultGlucoseUnits] isEqualToString:kGlucoseUnits_mgdL];

		highGlucoseWarningKey = mgdL ? kHighGlucoseWarning0 : kHighGlucoseWarning1;
		lowGlucoseWarningKey = mgdL ? kLowGlucoseWarning0 : kLowGlucoseWarning1;

/*
        UIButton* b = [UIButton buttonWithType:UIButtonTypeInfoLight];
		[b addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:b];
		[b release];
 */
	}
	return self;
}

- (void)dealloc
{
	[exportViewController release];
	[purgeViewController release];
	[super dealloc];
}

- (void) doneAction:(id)sender
{
	// Cancel edit mode in case the controllers are reused later
	[categoryViewController setEditing:NO animated:NO];	
	[insulinTypeViewController setEditing:NO animated:NO];
	[insulinTypeViewController setMultiCheck:NO];

	// Persist changes to NSUserDefaults
	[[NSUserDefaults standardUserDefaults] synchronize];

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.75];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
						   forView:self.navigationController.view cache:YES];
    [self.navigationController popViewControllerAnimated:NO];	
	[UIView commitAnimations];
}

- (void) glucoseUnitsAction:(UISegmentedControl*)sender
{
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	switch( sender.selectedSegmentIndex )
	{
		case 0:
			[defaults setObject:kGlucoseUnits_mgdL forKey:kDefaultGlucoseUnits];
			highGlucoseWarningKey = kHighGlucoseWarning0;
			lowGlucoseWarningKey = kLowGlucoseWarning0;
			highGlucoseWarningField.keyboardType = UIKeyboardTypeNumberPad;
			lowGlucoseWarningField.keyboardType = UIKeyboardTypeNumberPad;
			break;
		case 1:
			[defaults setObject:kGlucoseUnits_mmolL forKey:kDefaultGlucoseUnits];
			highGlucoseWarningKey = kHighGlucoseWarning1;
			lowGlucoseWarningKey = kLowGlucoseWarning1;
			highGlucoseWarningField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
			lowGlucoseWarningField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
			break;
	}
	highGlucoseWarningField.text = [defaults stringForKey:highGlucoseWarningKey];
	lowGlucoseWarningField.text = [defaults stringForKey:lowGlucoseWarningKey];
	// Force the LogViewController to reload the LogEntryViewController so it can pick up the change
	appDelegate.logViewController.logEntryViewController = nil;
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch( section )
	{
		case 0: return 2;
        case 1: return 3;
		case 2: return 3;
		case 3: return 3;
    }
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellID = @"CellID";
	
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
	if( !cell )
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
		cell.textAlignment = UITextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	// Default all rows to bold, black and label-sized
	cell.textColor = [UIColor darkTextColor];
	cell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];

    switch( indexPath.section )
	{
		case 0:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			switch( indexPath.row )
			{
				case 0: cell.text = @"Export"; break;
				case 1: cell.text = @"Purge"; break;
			}
			break;
		case 1:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			switch( indexPath.row )
			{
				case 0: cell.text = @"Categories"; break;
				case 1: cell.text = @"Insulin Types"; break;
				case 2: cell.text = @"Default Insulin Types"; break;
			}
			break;
		case 2:
			cell.textAlignment = UITextAlignmentLeft;
			UITextField* f;
			NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
			const BOOL mgdL = [[defaults objectForKey:kDefaultGlucoseUnits] isEqualToString:kGlucoseUnits_mgdL];
			if( indexPath.row < 2 )
			{
				f = [[UITextField alloc] initWithFrame:CGRectMake(0, kCellTopOffset*2, 50, 20)];
				f.delegate = self;
				f.keyboardType = mgdL ? UIKeyboardTypeNumberPad : UIKeyboardTypeNumbersAndPunctuation;
				f.textAlignment = UITextAlignmentRight;
				cell.accessoryView = f;
			}
			switch( indexPath.row )
			{
				case 0:
					cell.text = @"High Glucose Warning";
					f.text = [defaults stringForKey:highGlucoseWarningKey];
					f.textColor = [UIColor blueColor];
					highGlucoseWarningCell = cell;
					highGlucoseWarningField = f;
					break;
				case 1:
					cell.text = @"Low Glucose Warning";
					f.text = [defaults stringForKey:lowGlucoseWarningKey];
					f.textColor = [UIColor redColor];
					lowGlucoseWarningCell = cell;
					lowGlucoseWarningField = f;
					break;
				case 2:
					cell.text = @"Glucose Units";
					UISegmentedControl* s = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:kGlucoseUnits_mgdL,kGlucoseUnits_mmolL,nil]];
					s.segmentedControlStyle = UISegmentedControlStyleBar;
					[s addTarget:self action:@selector(glucoseUnitsAction:) forControlEvents:UIControlEventValueChanged];
					s.selectedSegmentIndex = mgdL ? 0 : 1;
					cell.accessoryView = s;
					break;
			}
			break;
        case 3:
			cell.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
			if( indexPath.row )
				cell.textColor = [UIColor blueColor];	// Website and email links
			switch(indexPath.row )
			{
				case 0:
				{
					NSBundle *const mainBundle = [NSBundle mainBundle];
					NSString *const v = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
					NSString *const n = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
					cell.text = [NSString stringWithFormat:@"%@ v%@", n, v];
				}
				break;
				case 1: cell.text = @"Brandon Fosdick <bfoz@bfoz.net>"; break;
				case 2: cell.text = @"http://bfoz.net/projects/glucose"; break;
			}
			break;
    }

	return cell;
}
/*
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    switch( section )
	{
        case 0: return @"About";
    }
    return nil;
}
*/

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section)
	{
		case 0:
			switch( indexPath.row )
			{
				case 0:
					if( !exportViewController )
						exportViewController = [[ExportViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:exportViewController animated:YES];
					break;
				case 1:
					if( !purgeViewController )
						purgeViewController = [[PurgeViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:purgeViewController animated:YES];
					break;
			}
			break;
		case 1:
			switch( indexPath.row )
			{
				case 0:
					if( !categoryViewController )	// Get the view controller from appDelegate
						categoryViewController = appDelegate.categoryViewController;
					[self.navigationController pushViewController:categoryViewController animated:YES];
					// Set editing mode after pushing the view controller. The UITableView doesn't exist
					//  until loadView has been called. Until then, there's nothing to set editing mode on.
					[categoryViewController setEditing:YES animated:NO];
					break;
				case 1:
					if( !insulinTypeViewController )
						insulinTypeViewController = appDelegate.insulinTypeViewController;
					[insulinTypeViewController setMultiCheck:NO];
					[self.navigationController pushViewController:insulinTypeViewController animated:YES];
					// Set editing mode after pushing the view controller. The UITableView doesn't exist
					//  until loadView has been called. Until then, there's nothing to set editing mode on.
					[insulinTypeViewController setEditing:YES animated:NO];
					break;
				case 2:
					if( !insulinTypeViewController )
						insulinTypeViewController = appDelegate.insulinTypeViewController;
					[insulinTypeViewController setEditing:NO];
					[insulinTypeViewController setMultiCheck:YES];
					[self.navigationController pushViewController:insulinTypeViewController animated:YES];
					break;
			}
			break;
		case 2:
			switch( indexPath.row )
			{
				case 0:
					[highGlucoseWarningField becomeFirstResponder];
					break;
				case 1:
					[lowGlucoseWarningField becomeFirstResponder];
					break;
			}
			break;
		case 3:
			if( indexPath.row == 0 )
			{
				NSString* e = [@"mailto:bfoz@bfoz.net?subject=Glucose" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:e]];
			}
			if( indexPath.row == 1 )
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bfoz.net/projects/glucose/"]];
			break;
	}
}

/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
	}
	if (editingStyle == UITableViewCellEditingStyleInsert) {
	}
}
*/

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

/*
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (CGFloat) tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
	return (3 == section) ? 40 : 0;
}

- (UIView*) tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
	if( 3 == section )
	{
		UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.text = @"Copyright 2008 Brandon Fosdick";
		label.textAlignment = UITextAlignmentCenter;
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];;
		return label;
	}
	return nil;
}

/*
- (void)viewDidLoad {
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}
*/
#pragma mark -
#pragma mark <UITextFieldDelegate>

- (UITableViewCell*) cellForField:(UITextField*)field
{
	if( field == highGlucoseWarningField )
		return highGlucoseWarningCell;
	else if( field == lowGlucoseWarningField )
		return lowGlucoseWarningCell;
	return nil;
}

- (SEL) selectorForField:(UITextField*)field
{
	if( field == highGlucoseWarningField )
		return @selector(saveHighGlucoseWarningAction);
	else if( field == lowGlucoseWarningField )
		return @selector(saveLowGlucoseWarningAction);
	return nil;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField*)field
 {
	 return [self shouldBeginEditing:[self cellForField:field]];
 }
 
- (void)textFieldDidBeginEditing:(UITextField*)field
{
	[self didBeginEditing:[self cellForField:field] field:field action:[self selectorForField:field]];
}

- (void)saveHighGlucoseWarningAction
{
	[[NSUserDefaults standardUserDefaults] setObject:[editField text] forKey:highGlucoseWarningKey];
	[self saveAction];
}

- (void)saveLowGlucoseWarningAction
{
	[[NSUserDefaults standardUserDefaults] setObject:[editField text] forKey:lowGlucoseWarningKey];
	[self saveAction];
}

@end

