//
//  SettingsViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "SettingsViewController.h"
#import "CategoryViewController.h"
#import "InsulinTypeViewController.h"

@interface SettingsViewController ()

//@property (nonatomic, retain) CategoryViewController* categoryViewController;

@end

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
		((UITableView*)self.view).separatorStyle = UITableViewCellSeparatorStyleNone;
/*
        UIButton* b = [UIButton buttonWithType:UIButtonTypeInfoLight];
		[b addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:b];
		[b release];
 */
	}
	return self;
}
/*
- (void)dealloc
{
	[super dealloc];
}
*/

- (void) doneAction:(id)sender
{
	// Cancel edit mode in case the controllers are reused later
	[categoryViewController setEditing:NO];	
	[insulinTypeViewController setEditing:NO];
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

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch( section )
	{
        case 0: return 3;
		case 1: return 3;
		case 2: return 2;
    }
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if( !cell )
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		cell.textAlignment = UITextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textColor = [UIColor darkTextColor];
/*
		switch( indexPath.section )
		{
			case 0:
				cell.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
				if( (indexPath.row == 2) || (indexPath.row == 3) )
					cell.textColor = [UIColor blueColor];	// Website and email links
				break;
			case 1:
//				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				break;				
		}
*/	}

    switch( indexPath.section )
	{
        case 0:
			cell.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
			if( (indexPath.row == 1) || (indexPath.row == 2) )
				cell.textColor = [UIColor blueColor];	// Website and email links
			switch(indexPath.row )
			{
				case 0: cell.text = @"Glucose Version 0.1"; break;
				case 1: cell.text = @"bfoz@bfoz.net"; break;
				case 2: cell.text = @"http://bfoz.net/projects/glucose"; break;
			}
			break;
		case 1:
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			switch( indexPath.row )
			{
				case 0: cell.text = @"Categories"; break;
				case 1: cell.text = @"Insulin Types"; break;
				case 2: cell.text = @"Default Dose Types"; break;
			}
			break;
		case 2:
			cell.textAlignment = UITextAlignmentLeft;
			UITextField* f = [[UITextField alloc] initWithFrame:CGRectMake(0, kCellTopOffset*2, 50, 20)];
			f.delegate = self;
			f.keyboardType = UIKeyboardTypeNumberPad;
			f.textAlignment = UITextAlignmentRight;
			f.textColor = [UIColor grayColor];
			NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
			switch( indexPath.row )
			{
				case 0:
					cell.text = @"High Glucose Warning";
					f.text = [defaults stringForKey:@"HighGlucoseWarning"];
					highGlucoseWarningCell = cell;
					highGlucoseWarningField = f;
					break;
				case 1:
					cell.text = @"Low Glucose Warning";
					f.text = [defaults stringForKey:@"LowGlucoseWarning"];
					lowGlucoseWarningCell = cell;
					lowGlucoseWarningField = f;
					break;
			}
			cell.accessoryView = f;
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
	// Ignore all but sections 0 and 1
	if( indexPath.section > 1 )
		return;

	if( indexPath.section == 0 )
	{
		if( indexPath.row == 2 )
		{
			NSString* e = [@"mailto:bfoz@bfoz.net?subject=Glucose" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:e]];
		}
		if( indexPath.row == 3 )
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bfoz.net/projects/glucose/"]];
		return;
	}

	// Section 1
	switch( indexPath.row )
	{
		case 0:
			if( !categoryViewController )	// Get the view controller from appDelegate
				categoryViewController = appDelegate.categoryViewController;
			[categoryViewController setEditing:YES];
			[self.navigationController pushViewController:categoryViewController animated:YES];
			break;
		case 1:
			if( !insulinTypeViewController )
				insulinTypeViewController = appDelegate.insulinTypeViewController;
			[insulinTypeViewController setEditing:YES];
			[self.navigationController pushViewController:insulinTypeViewController animated:YES];
			break;
		case 2:
			if( !insulinTypeViewController )
				insulinTypeViewController = appDelegate.insulinTypeViewController;
			[insulinTypeViewController setEditing:NO];
			[insulinTypeViewController setMultiCheck:YES];
			[self.navigationController pushViewController:insulinTypeViewController animated:YES];
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
	if( 2 == section )
		return 40;
	return 0;
}

- (UIView*) tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
	if( 2 == section )
	{
//		UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 50)];
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
	UITableViewCell* cell = [self cellForField:field];
	[self didBeginEditing:cell field:field action:[self selectorForField:field]];
}

- (void)saveHighGlucoseWarningAction
{
	[[NSUserDefaults standardUserDefaults] setObject:[editField text] forKey:@"HighGlucoseWarning"];
	[self saveAction];
}

- (void)saveLowGlucoseWarningAction
{
	[[NSUserDefaults standardUserDefaults] setObject:[editField text] forKey:@"LowGlucoseWarning"];
	[self saveAction];
}

@end

