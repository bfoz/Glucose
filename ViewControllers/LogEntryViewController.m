//
//  LogEntryViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 6/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "DualTableViewCell.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "InsulinTypeViewController.h"
#import "LabelCell.h"
#import "LogEntryViewController.h"
#import "LogEntry.h"
#import "LogDay.h"
#import "LogModel.h"
#import "TextViewCell.h"

// Post-translation section numbers
#define	kGlucoseSectionNum		0
#define	kInsulinSectionNum		1
#define	kNoteSectionNum			2

#define	kInsulinCellID			@"InsulinCellID"

@interface LogEntryViewController ()

@property (nonatomic, retain)	NumberFieldCell*	glucoseCell;
@property (nonatomic, readonly) NSDateFormatter* dateFormatter;
@property (nonatomic, retain)	UITableViewCell*	cellTimestamp;


- (void)toggleDatePicker;
- (void) updateTitle;

@end

@implementation LogEntryViewController

@synthesize dateFormatter, entry, entrySection;
@synthesize delegate;
@synthesize editingNewEntry;
@synthesize glucoseCell;
@synthesize cellTimestamp;
@synthesize model;

static unsigned InsulinPrecision;
static NSUserDefaults* defaults = nil;

- (id)initWithStyle:(UITableViewStyle)style
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style])
    {
	didUndo = NO;
	editingNewEntry = NO;
	
	// Create a date formatter to convert the date to a string format.
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	if( !defaults )
	    defaults = [NSUserDefaults standardUserDefaults];
	NSNumber* p = [defaults objectForKey:kDefaultInsulinPrecision];
	InsulinPrecision = p ? [p intValue] : 0;
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
    [categoryViewController release];
    [insulinTypeViewController release];
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

    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(shaken)
						 name:@"shaken"
					       object:nil];

    didSelectRow = NO;		    // Remove any existing selection
    [self updateTitle];		    // Update the navigation item title
    [self.tableView reloadData];    // Redisplay the data
}

- (void)viewWillDisappear:(BOOL)animated
{
    if( !didSelectRow && self.editing )
	[self setEditing:NO animated:YES];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"shaken" object:nil];
    [super viewWillDisappear:animated];
}

- (void)setEditing:(BOOL)e animated:(BOOL)animated
{
    // Tell the entry first so it can flush itself and do any cleanup
    [entry setEditing:e model:model];

    /* If ending edit mode...
	Do this check before calling the super so that self.editing still
	reflects the previous edit state.
    */
    if( self.editing && !e )
    {
	if( [delegate respondsToSelector:@selector(logEntryViewDidEndEditing)] )
	    [delegate logEntryViewDidEndEditing];
    }

    // Not editing, so not editing a new entry
    if( !e )
	self.editingNewEntry = NO;

    // Finally pass the call to the super
    [super setEditing:e animated:animated];

    /* Update the navigation item title
	!!! Must be after calling the super so that self.editing is updated */
    [self updateTitle];

    // Reload the table to update the view to reflect the new edit state
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) updateTitle
{
    if( self.editingNewEntry )
	self.title = @"New Entry";
    else if( self.editing )
	self.title = @"Edit Entry";
    else
	self.title = @"Details";
}

#pragma mark Shake handling

- (void)shaken
{
    // Ignore shakes when not editing
    if( !self.editing )
	return;

    // If editing a field, revert that field
    if( editCell )
    {
	didUndo = YES;	    // Flag that an undo operation is happening
	[self saveAction];  // Cancel the edit
	[self.tableView reloadData];
    }
    else // otherwise revert the record and cancel editing
    {
	[entry revert:model];		    // Reload the entry from the database
	[self setEditing:NO animated:NO];   // Cancel edit mode
    }
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
	    case 1: return kInsulinCellID;
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
	if( kInsulinCellID == cellID )
	{
	    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
					   reuseIdentifier:cellID] autorelease];
	    // Use the same font size for both labels
	    cell.detailTextLabel.font = cell.textLabel.font;
	}
	else if( @"eDualCellID" == cellID )
	{
	    // CGRectZero allows the cell to determine the appropriate size.
	    cell = [[[DoseFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	    ((DoseFieldCell*)cell).delegate = self;
	}
	else if( @"eGlucose" == cellID )
	{
	    glucoseCell = [[[NumberFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	    glucoseCell.clearButtonMode = UITextFieldViewModeWhileEditing;
	    glucoseCell.delegate = self;
	    glucoseCell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	    glucoseCell.placeholder = @"Glucose";
	    cell = glucoseCell;
	}
	else if( @"NoteCellID" == cellID )
	{
	    cell = [[[TextViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	    ((TextViewCell*)cell).placeholder = @"Note";
	    ((TextViewCell*)cell).delegate = self;
	}
	else if( @"NoteID" == cellID )
	{
	    cell = [[LabelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	}
	else	// Standard UITableView cell for Timestamp and Category
	{
	    // CGRectZero allows the cell to determine the appropriate size.
	    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	    cell.textLabel.textAlignment = UITextAlignmentCenter;
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
		cell.textLabel.text = [dateFormatter stringFromDate:entry.timestamp];
		break;
	    case 1:	// Category
		if( entry.category )
		{
		    cell.textLabel.text = entry.category.categoryName;
		    cell.textLabel.textColor = [UIColor darkTextColor];
		}
		else
		{
		    cell.textLabel.text = @"Category";
		    cell.textLabel.textColor = [UIColor lightGrayColor];
		}
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
		    NSString *const units = entry.glucoseUnits;
		    const unsigned precision = (units == kGlucoseUnits_mgdL) ? 0 : 1;
		    cell.textLabel.text = entry.glucose ? [NSString localizedStringWithFormat:@"%.*f%@", precision, [entry.glucose floatValue], units] : nil;
		    // Color the glucose values accordingly
		    NSString* keyHigh;
		    NSString* keyLow;
		    if( units == kGlucoseUnits_mgdL )
		    {
			keyHigh = kHighGlucoseWarning0;
			keyLow = kLowGlucoseWarning0;
		    }
		    else
		    {
			keyHigh = kHighGlucoseWarning1;
			keyLow = kLowGlucoseWarning1;
		    }
		    if( [entry.glucose floatValue] > [defaults floatForKey:keyHigh] )
			cell.textLabel.textColor = [UIColor blueColor];
		    else if( [entry.glucose floatValue] < [defaults floatForKey:keyLow] )
			cell.textLabel.textColor = [UIColor redColor];
		    else
			cell.textLabel.textColor = [UIColor darkTextColor];
		}
		break;
	}
    }
    else if( 1 == section )
    {
	// If the entry doesn't have a valid number for an insulin type use a regular cell and display the short name. 
	// Otherwise, use a dual column cell.
	InsulinDose* dose = [entry doseAtIndex:row];

	if( kInsulinCellID == cellID )
	{
	    while( !(dose && dose.dose && dose.type) )
		dose = [entry doseAtIndex:++row];
	    if( dose )
	    {
		if( dose.dose )	// If the record has a valid value...
		{
		    cell.detailTextLabel.text = [dose.dose stringValue];    // Value
		    cell.textLabel.text = dose.type.shortName;		    // Name
		}
		else if(dose.type)
		    cell.textLabel.text = dose.type.shortName;
	    }
	}
	else if( @"eDualCellID" == cellID )
	{
	    DoseFieldCell *const dcell = (DoseFieldCell*)cell;
	    dcell.dose = dose;
	    dcell.precision = InsulinPrecision;
	}
    }
    else if( 2 == section )
    {
	cell.textLabel.text = entry.note;

	// In editing mode, the cell is actually a TextViewCell that sets it's text differently
	if( self.editing )
	    ((TextViewCell *)cell).text = entry.note;
    }

    if( self.editing )
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
	cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)path
{
    if( UITableViewCellEditingStyleDelete == editingStyle )
    {
	[entry removeDoseAtIndex:path.row];
	[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if( UITableViewCellEditingStyleInsert == editingStyle )
    {
	// Fake a row selection to display the insulin picker
	[self tableView:tv didSelectRowAtIndexPath:path];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( 2 == section )
	return @"Note";
    return nil;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)path
{
    if( 1 == path.section )
	return YES;
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only allow selection if editing.
    return (self.editing) ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path
{
    const unsigned row = path.row;
    const unsigned section = [self translateSection:path.section];

    if( 0 == section )
    {
	didSelectRow = YES; // The next viewWillDisapper is from a push, not a pop
	switch( path.row )
	{
	    case 0: 
		[self toggleDatePicker];
		break;
	    case 1: 
		if( !categoryViewController )
		{
		    categoryViewController = [[CategoryViewController alloc] initWithStyle:UITableViewStylePlain];
		    categoryViewController.delegate = self;
		    categoryViewController.model = model;
		}
		categoryViewController.selectedCategory = entry.category;
		[self presentModalViewController:categoryViewController animated:YES];
		break;
	    case 2: // Go into edit mode if the user taps anywhere on the row
		[glucoseCell becomeFirstResponder];
		break;
	}
    }
    else if( 1 == section )
    {
	didSelectRow = YES; // The next viewWillDisapper is from a push, not a pop
	if( !insulinTypeViewController )
	{
	    insulinTypeViewController = [[InsulinTypeViewController alloc] initWithStyle:UITableViewStylePlain];
	    insulinTypeViewController.delegate = self;
	    insulinTypeViewController.model = model;
	}
	editedIndex = row;
	[insulinTypeViewController setSelectedInsulinType:(InsulinType*)[[[entry insulin] objectAtIndex:row] type]];
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
    cellTimestamp.textLabel.text = [dateFormatter stringFromDate:entry.timestamp];
}

#pragma mark -
#pragma mark <NumberFieldCellDelegate>

- (void)numberFieldCellDidBeginEditing:(NumberFieldCell*)cell
{
    [self didBeginEditing:cell field:cell.field action:@selector(saveGlucoseAction:)];
}

- (void)numberFieldCellDidEndEditing:(NumberFieldCell*)cell
{
    if( didUndo )
	didUndo = NO;	// Undo handled
    else if( cell == glucoseCell )
	entry.glucose = cell.number;
    [self didEndEditing];
}

- (void)saveGlucoseAction:(id)sender
{
    [(NumberFieldCell*)editCell resignFirstResponder];
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
#pragma mark <CategoryViewControllerDelegate>

- (void) categoryViewControllerDidSelectCategory:(Category *)category
{
    entry.category = category;
    if( editingNewEntry )
	[glucoseCell becomeFirstResponder];
}

#pragma mark -
#pragma mark <DoseFieldCellDelegate>

- (void)doseDidBeginEditing:(DoseFieldCell*)cell
{
    [self didBeginEditing:cell field:cell.doseField action:@selector(saveDoseAction:)];
}

- (void)doseDidEndEditing:(DoseFieldCell *)cell
{
    if( didUndo )
	didUndo = NO;	// Undo handled
    else
	[entry setDose:[cell.doseField number] insulinDose:cell.dose];
    [self didEndEditing];
}

- (void)saveDoseAction:(id)sender
{
    if( editingNewEntry )
    {
	// Get the index path for the next insulin row. If there is no next row, find the note row
	NSIndexPath* path = [[tableView indexPathForCell:editCell] retain];
	NSIndexPath* next = [[NSIndexPath indexPathForRow:path.row+1 inSection:kInsulinSectionNum] retain];
	[path release];
	UITableViewCell* cell = [[tableView cellForRowAtIndexPath:next] retain];
	[next release];
	if( cell )	// Found a next insulin row
	{
	    [tableView scrollToRowAtIndexPath:next atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	    [((DoseFieldCell*)cell).doseField becomeFirstResponder];
	}
	else		// Resign first responder if no more insulin rows
	    [((DoseFieldCell*)editCell).doseField resignFirstResponder];
	[cell release];
    }
    else
	[((DoseFieldCell*)editCell).doseField resignFirstResponder];
}

#pragma mark -
#pragma mark <InsulinTypeViewControllerDelegate>

- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(InsulinType*)type
{
    // Update the insulin type for the entry's dose. If the entry doesn't have
    //	a dose at the specified index, append a new dose object with the
    //	selected type.
    if( editedIndex < [entry.insulin count] )
	[entry setDoseType:type at:editedIndex];
    else
	[entry addDoseWithType:type];
    return YES;
}

#pragma mark -
#pragma mark <TextViewCellDelegate>

- (void)textViewCellDidBeginEditing:(TextViewCell*)cell
{
    [self didBeginEditing:cell field:cell.view action:@selector(saveNoteAction:)];
}

- (void)saveNoteAction:(id)sender
{
    if( didUndo )
	didUndo = NO;	// Undo handled
    else
    {
	entry.note = ((TextViewCell *)editCell).text;
	[self saveAction];
    }
}

@end
