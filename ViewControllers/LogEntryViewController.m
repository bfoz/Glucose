#import "AppDelegate.h"
#import "CategoryViewController.h"
#import "Constants.h"
#import "DateField.h"
#import "DoseFieldCell.h"
#import "DualTableViewCell.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "InsulinTypeViewController.h"
#import "LabelCell.h"
#import "LogEntryViewController.h"
#import "LogEntry.h"
#import "LogDay.h"
#import "LogModel.h"
#import "NumberFieldCell.h"
#import "TextViewCell.h"

#define	kInsulinCellID			@"InsulinCellID"

enum Sections
{
    kSectionGlucose = 0,
    kSectionInsulin,
    kSectionNote,
    NUM_SECTIONS
};

@interface LogEntryViewController () <CategoryViewControllerDelegate, DateFieldDelegate, DoseFieldCellDelegate, InsulinTypeViewControllerDelegate, NumberFieldCellDelegate, TextViewCellDelegate>
{
    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	insulinTypeViewController;

    BOOL	didSelectRow;
    BOOL	didUndo;
    unsigned	editedIndex;
}

@property (nonatomic, strong) NSDateFormatter*	dateFormatter;
@property (nonatomic, unsafe_unretained) UITableViewCell*	timestampCell;

@property (nonatomic, strong) UILabel*	categoryLabel;
@property (nonatomic, strong) UILabel*	timestampLabel;

@end

@implementation LogEntryViewController
{
    NumberFieldCell*	glucoseCell;
    DateField*	    timestampField;
}

@synthesize categoryLabel, timestampLabel;
@synthesize dateFormatter, entrySection;
@synthesize delegate;
@synthesize editingNewEntry;
@synthesize logEntry = _logEntry;
@synthesize timestampCell;
@synthesize model;

static unsigned InsulinPrecision;
static NSUserDefaults* defaults = nil;

- (id) initWithStyle:(UITableViewStyle)style
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id) initWithLogEntry:(LogEntry*)logEntry
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if( self )
    {
	didUndo = NO;
	editingNewEntry = NO;
	
	self.logEntry = logEntry;

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    didSelectRow = NO;		    // Remove any existing selection
    [self updateTitle];		    // Update the navigation item title
    [self.tableView reloadData];    // Redisplay the data
}

- (void)viewWillDisappear:(BOOL)animated
{
    if( !didSelectRow && self.editing )
	[self setEditing:NO animated:YES];

    [super viewWillDisappear:animated];
}

- (void)setEditing:(BOOL)e animated:(BOOL)animated
{
    // Tell the entry first so it can flush itself and do any cleanup
    [self.logEntry setEditing:e model:model];

    /* If ending edit mode...
	Do this check before calling the super so that self.editing still
	reflects the previous edit state.
    */
    if( self.editing && !e )
	[delegate logEntryView:self didEndEditingEntry:self.logEntry];

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

- (void) updateTitle
{
    if( self.editingNewEntry )
	self.title = @"New Entry";
    else if( self.editing )
	self.title = @"Edit Entry";
    else
	self.title = @"Details";
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    if( self.editing )
	return NUM_SECTIONS;
    else
	return 1 + ([self.logEntry.insulin count] ? 1 : 0) + (self.logEntry.note && [self.logEntry.note length] ? 1 : 0);
}

// Section 0 - Timestamp/Category/Glucose
//	Row 0 => Row 0
//	Row 2 (Glucose) => Row 1 if not editing and there is a glucose reading, but no category
- (unsigned) translateRow:(unsigned)row inSection:(unsigned)section
{
    if( !self.editing && (0 == section) && (1==row) && !self.logEntry.category && self.logEntry.glucose )
	return 2;
    return row;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    switch( section )
    {
	case 0:
	    if( self.editing )
		return 3;
	    else
		return 1 + (self.logEntry.glucose ? 1 : 0) + (self.logEntry.category ? 1 : 0);
	case 1:
	    if( self.editing )
		return [self.logEntry.insulin count];
	    else
	    {
		unsigned i = 0;
		for( InsulinDose* d in self.logEntry.insulin )
		    if( d.dose && d.insulinType )
			++i;
		return i;
	    }
	case 2:
	    if( self.editing )
		return 1;
	    else
		return self.logEntry.note && [self.logEntry.note length] ? 1 : 0;
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
    if( self.logEntry == nil )
	return nil;

    const unsigned section = indexPath.section;
    unsigned row = [self translateRow:indexPath.row inSection:section];

    NSString *const cellID = [self cellIDForSection:section row:row];

    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];	// Get the appropriate cell

    if( !cell )	// Create a new cell if needed
    {
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	if( (kSectionGlucose == section) && (0 == row) )
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	else if( kInsulinCellID == cellID )
	{
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
					   reuseIdentifier:cellID];
	    // Use the same font size for both labels
	    cell.detailTextLabel.font = cell.textLabel.font;
	    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
	    cell.textLabel.backgroundColor = [UIColor clearColor];
	}
	else if( @"eDualCellID" == cellID )
	{
	    // CGRectZero allows the cell to determine the appropriate size.
	    cell = [[DoseFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    ((DoseFieldCell*)cell).delegate = self;
	}
	else if( @"eGlucose" == cellID )
	{
	    glucoseCell = [[NumberFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    glucoseCell.clearButtonMode = UITextFieldViewModeWhileEditing;
	    glucoseCell.delegate = self;
	    glucoseCell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	    glucoseCell.placeholder = @"Glucose";
	    cell = glucoseCell;
	}
	else if( @"NoteCellID" == cellID )
	{
	    cell = [[TextViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    ((TextViewCell*)cell).placeholder = @"Note";
	    ((TextViewCell*)cell).delegate = self;
	}
	else if( @"NoteID" == cellID )
	{
	    cell = [[LabelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	}
	else	// Standard UITableView cell for Timestamp and Category
	{
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    cell.textLabel.backgroundColor = [UIColor clearColor];
	    cell.textLabel.textAlignment = UITextAlignmentCenter;
	    if( (0 == section) && (0 == row) )	// Save a pointer to the timestamp cell
	    {}
	    else
		self.categoryLabel = cell.textLabel;
	}
    }

    if( kSectionGlucose == section )
    {
	switch( row )
	{
	    case 0:	// Timestamp
	    {
		cell.textLabel.text = [dateFormatter stringFromDate:self.logEntry.timestamp];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		timestampField = [[DateField alloc] initWithFrame:cell.textLabel.frame];
		timestampField.delegate = self;
		timestampField.hidden = YES;
		[cell addSubview:timestampField];
		self.timestampCell = cell;
		self.timestampLabel = cell.textLabel;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		break;
	    }
	    case 1:	// Category
		if( self.logEntry.category )
		{
		    cell.textLabel.text = self.logEntry.category.categoryName;
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
		    if( self.logEntry.glucoseUnits && (self.logEntry.glucoseUnits == kGlucoseUnits_mmolL) )
			glucoseCell.precision = 1;
		    else
			glucoseCell.precision = 0;
		    glucoseCell.number = self.logEntry.glucose;
		    glucoseCell.label = self.logEntry.glucoseUnits;
		}
		else
		{
		    NSString *const units = self.logEntry.glucoseUnits;
		    const unsigned precision = (units == kGlucoseUnits_mgdL) ? 0 : 1;
		    cell.textLabel.text = self.logEntry.glucose ? [NSString localizedStringWithFormat:@"%.*f%@", precision, [self.logEntry.glucose floatValue], units] : nil;
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
		    if( [self.logEntry.glucose floatValue] > [defaults floatForKey:keyHigh] )
			cell.textLabel.textColor = [UIColor blueColor];
		    else if( [self.logEntry.glucose floatValue] < [defaults floatForKey:keyLow] )
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
	InsulinDose* dose = [self.logEntry doseAtIndex:row];

	if( kInsulinCellID == cellID )
	{
	    while( !(dose && dose.dose && dose.insulinType) )
		dose = [self.logEntry doseAtIndex:++row];
	    if( dose )
	    {
		if( dose.dose )	// If the record has a valid value...
		{
		    cell.detailTextLabel.text = [dose.dose stringValue];    // Value
		    cell.textLabel.text = dose.insulinType.shortName;		    // Name
		}
		else if(dose.insulinType)
		    cell.textLabel.text = dose.insulinType.shortName;
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
	cell.textLabel.text = self.logEntry.note;

	// In editing mode, the cell is actually a TextViewCell that sets it's text differently
	if( self.editing )
	    ((TextViewCell *)cell).text = self.logEntry.note;
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
	[self.logEntry removeDoseAtIndex:path.row];
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
    const unsigned section = path.section;

    if( 0 == section )
    {
	didSelectRow = YES; // The next viewWillDisapper is from a push, not a pop
	switch( path.row )
	{
	    case 0: 
		[timestampField becomeFirstResponder];
		[self.tableView deselectRowAtIndexPath:path animated:YES];
		break;
	    case 1: 
		if( !categoryViewController )
		{
		    categoryViewController = [[CategoryViewController alloc] initWithStyle:UITableViewStylePlain];
		    categoryViewController.delegate = self;
		    categoryViewController.model = model;
		}
		categoryViewController.selectedCategory = self.logEntry.category;
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
	[insulinTypeViewController setSelectedInsulinType:(InsulinType*)[[[self.logEntry insulin] objectAtIndex:row] insulinType]];
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

    if( indexPath.row >= [self.logEntry.insulin count] )
	return UITableViewCellEditingStyleInsert;
    else
	return UITableViewCellEditingStyleDelete;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)path
{
    if( kSectionNote == path.section )
    {
	const BOOL e = self.editing;
	// If editing and there's no text, return a standard size
	if( e && !self.logEntry.note )
	    return 44*2;
	// Otherwise, resize for the text
	CGSize s = [self.logEntry.note sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]
			  constrainedToSize:CGSizeMake(284, 2000) lineBreakMode:UILineBreakModeWordWrap];
	CGFloat h = s.height+2*kCellTopOffset;
	// If editing and the row started off with text, don't return smaller than two rows
	// Otherwise, never return smaller than one row
	return MAX(h, (e ? 44*2 : 44));
    }
    return 44;
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
	self.logEntry.glucose = cell.number;
    [self didEndEditing];
}

- (void)saveGlucoseAction:(id)sender
{
    [glucoseCell resignFirstResponder];
}

#pragma mark UITextFieldDelegate

- (void) dateFieldDidChangeValue:(DateField *)dateField
{
    timestampLabel.text = [dateFormatter stringFromDate:dateField.date];
}

- (void) textFieldDidBeginEditing:(DateField*)dateField
{
    dateField.date = self.logEntry.timestamp;
}

- (void) textFieldDidEndEditing:(DateField *)dateField
{
    if( timestampField )
	self.logEntry.timestamp = dateField.date;
    timestampField = dateField;
    timestampLabel.text = [dateFormatter stringFromDate:self.logEntry.timestamp];
}

- (void) dateFieldWillCancelEditing:(DateField *)dateField
{
    timestampField = nil;
}

#pragma mark -
#pragma mark <CategoryViewControllerDelegate>

- (void) categoryViewControllerDidSelectCategory:(Category *)category
{
    [self dismissModalViewControllerAnimated:YES];

    self.logEntry.category = category;
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
	[self.logEntry setDose:[cell.doseField number] insulinDose:cell.dose];
    [self didEndEditing];
}

- (void)saveDoseAction:(id)sender
{
    if( editingNewEntry )
    {
	// Get the index path for the next insulin row. If there is no next row, find the note row
	NSIndexPath* path = [tableView indexPathForCell:editCell];
	NSIndexPath* next = [NSIndexPath indexPathForRow:path.row+1 inSection:kSectionInsulin];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:next];
	if( cell )	// Found a next insulin row
	{
	    [tableView scrollToRowAtIndexPath:next atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	    [((DoseFieldCell*)cell).doseField becomeFirstResponder];
	}
	else		// Resign first responder if no more insulin rows
	    [((DoseFieldCell*)editCell).doseField resignFirstResponder];
    }
    else
	[((DoseFieldCell*)editCell).doseField resignFirstResponder];
}

#pragma mark -
#pragma mark <InsulinTypeViewControllerDelegate>

- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(InsulinType*)type
{
    [self dismissModalViewControllerAnimated:YES];

    // Update the insulin type for the entry's dose. If the entry doesn't have
    //	a dose at the specified index, append a new dose object with the
    //	selected type.
    if( editedIndex < [self.logEntry.insulin count] )
	[self.logEntry setDoseType:type at:editedIndex];
    else
	[self.logEntry addDoseWithType:type];
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
	self.logEntry.note = ((TextViewCell *)editCell).text;
	[self saveAction];
    }
}

@end
