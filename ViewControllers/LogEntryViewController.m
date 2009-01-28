//
//  LogEntryViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 6/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "CategoryViewController.h"
#import "DualTableViewCell.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "InsulinTypeViewController.h"
#import "LabelCell.h"
#import "LogEntryViewController.h"
#import "LogEntry.h"
#import "LogDay.h"
#import "TextViewCell.h"

// Post-translation section numbers
#define	kGlucoseSectionNum		0
#define	kInsulinSectionNum		1
#define	kNoteSectionNum			2

@interface LogEntryViewController ()

@property (nonatomic, retain)	NumberFieldCell*	glucoseCell;
@property (nonatomic, readonly) NSDateFormatter* dateFormatter;
@property (nonatomic, readonly) NSNumberFormatter* glucoseFormatter;
@property (nonatomic, readonly) NSNumberFormatter* numberFormatter;
@property (nonatomic, retain) CategoryViewController* categoryViewController;
@property (nonatomic, retain)	NSIndexPath*	selectedIndexPath;
@property (nonatomic, retain)	UITableViewCell*	cellTimestamp;


- (void)toggleDatePicker;

@end

@implementation LogEntryViewController

@synthesize categoryViewController, dateFormatter, entry, entrySection;
@synthesize glucoseFormatter, numberFormatter;
@synthesize glucoseCell;
@synthesize selectedIndexPath, cellTimestamp;

static AppDelegate* appDelegate = nil;

- (id)initWithStyle:(UITableViewStyle)style
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style])
	{
		self.title = @"Detail";

    	if( !appDelegate )
			appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		database = appDelegate.database;
		
		// Create a date formatter to convert the date to a string format.
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		
		// Create a date formatter to convert the date to a string format.
		numberFormatter = [[NSNumberFormatter alloc] init];
		
		// A number formatter for glucose measurements
		glucoseFormatter = [[NSNumberFormatter alloc] init];
		[glucoseFormatter setMaximumFractionDigits:1];
	}
    return self;
}
/*
- (void)loadView
{
//	NSArray* items = [NSArray arrayWithObjects:@"Details", @"Note"];
	NSMutableArray* items = [[NSMutableArray alloc] init];
	[items addObject:@"Detail"];
	[items addObject:@"Note"];
	UISegmentedControl* s = [[UISegmentedControl alloc] initWithItems:items];
	CGRect f = CGRectMake(10,50,100,100);
	UILabel* l = [[UILabel alloc] initWithFrame:f];
	l.text = @"Glucose";
	[v addSubview:s];
	[v addSubview:l];
}
*/
- (void)dealloc
{
	[selectedIndexPath release];
	[categoryViewController release];
    [numberFormatter release];
    [dateFormatter release];
	[super dealloc];
}

- (void)viewDidLoad
{
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    // Remove any existing selection.
	if( self.selectedIndexPath )
	{
		[self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
		self.selectedIndexPath = nil;
	}
    // Redisplay the data.
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if( self.selectedIndexPath == nil )
		[self setEditing:NO animated:YES];

	[super viewWillDisappear:animated];
}

- (void)setEditing:(BOOL)e animated:(BOOL)animated
{
    [super setEditing:e animated:animated];
	// Clear the selected index path whenever editing mode is cancelled
	//  because this view only uses selection in editing mode. Therefore, selectedIndexPath can be
	//  used as a state variable in viewWillDisapper
	if( !e && self.selectedIndexPath )
		self.selectedIndexPath = nil;
	if( e )
		[entry setEditing];
	else if( entry.dirty )
	{
		LogDay *const s = [appDelegate getSectionForDate:entry.timestamp];
		if ( s != entrySection )
		{
			[s insertEntry:entry];		// Add entry to new section
			// Remove from old section
			[appDelegate deleteLogEntry:entry fromSection:entrySection];
		}
		else	// Only need to update if above block was skipped
			[s updateStatistics];
		[entry flush:database];
	}
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
	if( self.editing )
		return 3;
	else
		return 1 + ([entry.insulin count] ? 1 : 0) + (entry.note && [entry.note length] ? 1 : 0);
}

// Section 0 - Timestamp/Category/Glucose
//	Row 0 => Row 0
//	Row 2 (Glucose) => Row 1 if not editing and there is a glucose reading, but no category
- (unsigned) translateRow:(unsigned)row inSection:(unsigned)section
{
	if( !self.editing && (0 == section) && (1==row) && !entry.category && entry.glucose )
		return 2;
	return row;
}

// Normally section 1 is the insulin does section. However, if there are no doses, section 1 becomes
//  the Note section. So remap section 1 to section 2.
- (unsigned) translateSection:(unsigned)section
{
	return ( !self.editing && (1==section) && ![entry.insulin count] ) ? 2 : section;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    switch( [self translateSection:section] )
	{
        case 0:
			if( self.editing )
				return 3;
			else
				return 1 + (entry.glucose ? 1 : 0) + (entry.category ? 1 : 0);
        case 1:
			if( self.editing )
				return [entry.insulin count];
			else
			{
				unsigned i = 0;
				for( InsulinDose* d in entry.insulin )
					if( d.dose && d.type )
						++i;
				return i;
			}
        case 2:
			if( self.editing )
				return 1;
			else
				return entry.note && [entry.note length] ? 1 : 0;
    }
    return 0;
}

- (NSString*) cellIDForSection:(unsigned)section row:(unsigned)row
{
	if( self.editing )
	{
		switch( section )
		{
			case 0:
				switch( row )
				{
					case 0: return @"Timestamp";
					case 1: return @"Category";
		    case 2: return @"eGlucose";
				}
				break;
			case 1: return @"eDualCellID";
			case 2: return @"NoteCellID";
		}
	}
	else
	{
		switch( section )
		{
			case 0:
				if( 2 == row )
					return @"Glucose";
				break;
			case 1:	return @"DualCellID";
			case 2: return @"NoteID";
		}
	}
	return @"CellID";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( entry == nil )
		return nil;

	const unsigned section = [self translateSection:indexPath.section];
	unsigned row = [self translateRow:indexPath.row inSection:section];

	NSString *const	cellID = [self cellIDForSection:section row:row];

	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];	// Get the appropriate cell

	if( !cell )	// Create a new cell if needed
	{
		if( @"DualCellID" == cellID )
		{
			// CGRectZero allows the cell to determine the appropriate size.
			cell = [[[DualTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
			((DualTableViewCell*)cell).leftTextAlignment = UITextAlignmentRight;
			((DualTableViewCell*)cell).rightTextAlignment = UITextAlignmentLeft;
		}
		else if( @"eDualCellID" == cellID )
		{
			// CGRectZero allows the cell to determine the appropriate size.
			cell = [[[DoseFieldCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
			((DoseFieldCell*)cell).delegate = self;
		}
	else if( @"eGlucose" == cellID )
	{
	    glucoseCell = [[[NumberFieldCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
	    glucoseCell.clearButtonMode = UITextFieldViewModeWhileEditing;
	    glucoseCell.delegate = self;
	    glucoseCell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	    glucoseCell.placeholder = @"Glucose";
	    cell = glucoseCell;
	}
		else if( @"NoteCellID" == cellID )
		{
			cell = [[[TextViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
			((TextViewCell*)cell).placeholder = @"Note";
			((TextViewCell*)cell).delegate = self;
		}
		else if( @"NoteID" == cellID )
		{
			cell = [[LabelCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID];
		}
		else	// Standard UITableView cell for Timestamp and Category
		{
			// CGRectZero allows the cell to determine the appropriate size.
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellID] autorelease];
			cell.textAlignment = UITextAlignmentCenter;
			if( (0 == section) && (0 == row) )	// Save a pointer to the timestamp cell
				self.cellTimestamp = cell;
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	if( 0 == section )
	{
		switch( row )
		{
			case 0:	// Timestamp
				cell.text = [dateFormatter stringFromDate:entry.timestamp];
				break;
			case 1:	// Category
				if( entry.category )
				{
					cell.text = entry.category.categoryName;
					cell.textColor = [UIColor darkTextColor];		
				}
				else
				{
					cell.text = @"Category";
					cell.textColor = [UIColor lightGrayColor];
				}
				cell.text = (entry.category == nil) ? @"Category" : entry.category.categoryName;
				break;
	    case 2:	// Glucose
		if( self.editing )
		{
		    // precision must be set before number so the display text is formatted correctly
		    if( entry.glucoseUnits && (entry.glucoseUnits == kGlucoseUnits_mmolL) )
			glucoseCell.precision = 1;
		    else
			glucoseCell.precision = 0;
		    glucoseCell.number = entry.glucose;
		    glucoseCell.label = entry.glucoseUnits;
		}
		else
		{
		    [glucoseFormatter setPositiveSuffix:entry.glucoseUnits];
		    [glucoseFormatter setNegativeSuffix:entry.glucoseUnits];
		    cell.text = entry.glucose ? [glucoseFormatter stringFromNumber:entry.glucose] : nil;
		}
		break;
		}
	}
	else if( 1 == section )
	{
		// If the entry doesn't have a valid number for an insulin type use a regular cell and display the short name. 
		// Otherwise, use a dual column cell.
		InsulinDose* dose = [entry.insulin objectAtIndex:row];

		if( @"DualCellID" == cellID )
		{
			while( !(dose && dose.dose && dose.type) )
				dose = [entry.insulin objectAtIndex:++row];
			if( dose )
			{
				if( dose.dose )	// If the record has a valid value...
				{
					// Get a DualTableViewCell
					DualTableViewCell* dcell = (DualTableViewCell*)cell;
					dcell.leftText = [dose.dose stringValue];	// Value
					if( dose.type )
						dcell.rightText = dose.type.shortName;	// Name
				}
				else if(dose.type)
					cell.text = dose.type.shortName;
			}
		}
		else if( @"eDualCellID" == cellID )
		{
			DoseFieldCell *const dcell = (DoseFieldCell*)cell;
			dcell.dose = dose;
		}
	}
	else if( 2 == section )
		cell.text = entry.note;

    return cell;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only allow selection if editing.
    return (self.editing) ? indexPath : nil;
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tv accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // Show the disclosure indicator if editing.
    return (self.editing) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{ 
	unsigned section = [self translateSection:indexPath.section];
	// Don't translate selectedIndexPath because it refers to a real table row
    self.selectedIndexPath = indexPath;	// State variable: indicate that the user is editing a particular field

	if( 0 == section )
	{
		switch( indexPath.row )
		{
			case 0: 
				[self toggleDatePicker];
				break;
			case 1: 
/*				if( !categoryViewController )
				{
					CategoryViewController* cvc = [[CategoryViewController alloc] initWithStyle:UITableViewStylePlain];
					self.categoryViewController = cvc;
					[cvc release];
				}*/
				if( !categoryViewController )	// Get the view controller from appDelegate
					self.categoryViewController = appDelegate.categoryViewController;
				categoryViewController.editedObject = entry;
//				[self.navigationController pushViewController:categoryViewController animated:YES];
				[self presentModalViewController:categoryViewController animated:YES];
				break;
	    case 2: // Go into edit mode if the user taps anywhere on the row
		[glucoseCell becomeFirstResponder];
		break;
		}
	}
	else if( 1 == section )
	{
		if( !insulinTypeViewController )
			insulinTypeViewController = [[InsulinTypeViewController alloc] initWithStyle:UITableViewStylePlain];
		insulinTypeViewController.editedObject = entry;
		insulinTypeViewController.editedIndex = indexPath.row;
		[self presentModalViewController:insulinTypeViewController animated:YES];
	}
	else if( 2 == section )
	{
	}
}

// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tv editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // No editing style if not editing or the index path is nil.
    if( !self.editing || !indexPath )
		return UITableViewCellEditingStyleNone;

	// Only section 1 can be edited (insulin doses)
	if( indexPath.section != 1 )
		return UITableViewCellEditingStyleNone;

	if( indexPath.row >= [entry.insulin count] )
		return UITableViewCellEditingStyleInsert;
	else
		return UITableViewCellEditingStyleDelete;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)path
{
	if( kNoteSectionNum == [self translateSection:path.section] )
	{
		const BOOL e = self.editing;
		// If editing and there's no text, return a standard size
		if( e && !entry.note )
			return 44*2;
		// Otherwise, resize for the text
		CGSize s = [entry.note sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]
						  constrainedToSize:CGSizeMake(284, 2000) lineBreakMode:UILineBreakModeWordWrap];
		CGFloat h = s.height+2*kCellTopOffset;
		// If editing and the row started off with text, don't return smaller than two rows
		// Otherwise, never return smaller than one row
		return MAX(h, (e ? 44*2 : 44));
	}
	return 44;
}

#pragma mark -
#pragma mark Timestamp picker

- (void)toggleDatePicker
{
	if( !(editCell == cellTimestamp) )
		[self showDatePicker:cellTimestamp mode:UIDatePickerModeDateAndTime initialDate:entry.timestamp changeAction:@selector(dateChangeAction)];
	else
		[self hideDatePicker];
}

- (void)dateChangeAction
{
	entry.timestamp = datePicker.date;
	cellTimestamp.text = [dateFormatter stringFromDate:entry.timestamp];
}

#pragma mark -
#pragma mark <NumberFieldCellDelegate>

- (BOOL)numberFieldCellShouldBeginEditing:(NumberFieldCell*)cell
{
	return [self shouldBeginEditing:cell];
}

- (void)numberFieldCellDidBeginEditing:(NumberFieldCell*)cell
{
    [self didBeginEditing:cell field:cell.field action:@selector(saveGlucoseAction:)];
}

- (void)numberFieldCellDidEndEditing:(NumberFieldCell*)cell
{
    if( cell == glucoseCell )
	entry.glucose = cell.number;
}

- (void)saveGlucoseAction:(id)sender
{
    [(NumberFieldCell*)editCell resignFirstResponder];
	[self saveAction];
}

#pragma mark -
#pragma mark <UITextFieldDelegate>
/*
- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
	NSLog(@"textFieldShouldBeginEditing");
	// Don't display units while the glucose field is being edited (they get in the way)
	if( textField == glucoseTextField )
	{
		NSLog(@"begin editing %@ = %@", textField.placeholder, textField.text);
		if( textField.text.length == 0 )
		if( entry.glucose == nil )
			textField.text = @"";
		else
			textField.text = [entry.glucose stringValue];
	}
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
	return YES;
}
*/

#pragma mark -
#pragma mark <DoseFieldCellDelegate>

- (BOOL)doseShouldBeginEditing:(DoseFieldCell*)cell
{
	return [self shouldBeginEditing:cell];
}

- (void)doseDidBeginEditing:(DoseFieldCell*)cell
{
	[self didBeginEditing:cell field:cell.doseField action:@selector(saveDoseAction:)];
}

- (void)doseDidEndEditing:(DoseFieldCell *)cell
{
	[entry setDose:[numberFormatter numberFromString:cell.doseField.text] insulinDose:cell.dose];
//	cell.dose.dose = [numberFormatter numberFromString:cell.doseField.text];
}

- (void)saveDoseAction:(id)sender
{
	[((DoseFieldCell*)editCell).doseField resignFirstResponder];
	[self saveAction];
}

#pragma mark -
#pragma mark <TextViewCellDelegate>

- (BOOL) textViewCellShouldBeginEditing:(TextViewCell*)cell
{
	return [self shouldBeginEditing:cell];
}

- (void)textViewCellDidBeginEditing:(TextViewCell*)cell
{
	[self didBeginEditing:cell field:cell.view action:@selector(saveNoteAction:)];
}

- (void)saveNoteAction:(id)sender
{
	entry.note = ((TextViewCell *)editCell).view.text;
	[self saveAction];
}

@end
