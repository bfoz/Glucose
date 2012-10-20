#import "AppDelegate.h"
#import "Category.h"
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

@property (nonatomic, strong) UILabel*	categoryLabel;
@property (nonatomic, strong) UILabel*	timestampLabel;

@end

@implementation LogEntryViewController
{
    NumberFieldCell*	glucoseCell;
    DateField*	    timestampField;
    UIToolbar*	    inputToolbar;
    UITextField*    currentEditingField;
}

@synthesize categoryLabel, timestampLabel;
@synthesize dateFormatter, entrySection;
@synthesize delegate;
@synthesize editingNewEntry;
@synthesize logEntry = _logEntry;
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

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if( ![self isMovingToParentViewController] )
	if( editingNewEntry )
	    [glucoseCell becomeFirstResponder];
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

#pragma mark Accessor

- (UIToolbar*) inputToolbar
{
    if( !inputToolbar )
    {
	inputToolbar = [[UIToolbar alloc] init];
	UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton)];
	UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDoneButton)];
	[inputToolbar setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, barButton, nil] animated:NO];
	[inputToolbar sizeToFit];
    }
    return inputToolbar;
}

#pragma mark Actions

- (void) didTapCancelButton
{
    UITextField* tmp = currentEditingField;
    currentEditingField = nil;
    [tmp resignFirstResponder];
}

- (void) didTapDoneButton
{
    [currentEditingField resignFirstResponder];
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
	case kSectionInsulin:
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
	{
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    cell.accessoryType = self.editing ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	}
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
	    DoseFieldCell* doseFieldCell = [[DoseFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    doseFieldCell.delegate = self;
	    doseFieldCell.doseField.inputAccessoryView = self.inputToolbar;
	    cell = doseFieldCell;
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if( @"eGlucose" == cellID )
	{
	    glucoseCell = [[NumberFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    glucoseCell.clearButtonMode = UITextFieldViewModeWhileEditing;
	    glucoseCell.delegate = self;
	    glucoseCell.field.inputAccessoryView = self.inputToolbar;
	    glucoseCell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	    glucoseCell.placeholder = @"Glucose";
	    cell = glucoseCell;
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if( @"NoteCellID" == cellID )
	{
	    TextViewCell* textViewCell = [[TextViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    textViewCell.placeholder = @"Add a Note";
	    textViewCell.delegate = self;
	    textViewCell.textView.inputAccessoryView = self.inputToolbar;

	    cell = textViewCell;
	    cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else if( @"NoteID" == cellID )
	{
	    cell = [[LabelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	}
	else	// Standard UITableView cell for Timestamp and Category
	{
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    cell.accessoryType = self.editing ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
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
		    glucoseCell.precision = self.logEntry.glucosePrecision;
		    glucoseCell.number = self.logEntry.glucose;
		    glucoseCell.labelText = self.logEntry.glucoseUnits;
		}
		else
		{
		    NSString *const units = self.logEntry.glucoseUnits;
		    cell.textLabel.text = self.logEntry.glucose ? [NSString localizedStringWithFormat:@"%.*f%@", self.logEntry.glucosePrecision, [self.logEntry.glucose floatValue], units] : nil;
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
    else if( kSectionInsulin == section )
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
    else if( kSectionNote == section )
    {
	cell.textLabel.text = self.logEntry.note;

	// In editing mode, the cell is actually a TextViewCell that sets it's text differently
	if( self.editing )
	    ((TextViewCell *)cell).text = self.logEntry.note;
    }

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
    else if( kSectionInsulin == section )
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

#pragma mark NumberFieldCellDelegate

- (void)numberFieldCellDidBeginEditing:(NumberFieldCell*)cell
{
    currentEditingField = cell.field;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)numberFieldCellDidEndEditing:(NumberFieldCell*)cell
{
    if( currentEditingField )
    {
	if( cell == glucoseCell )
	    self.logEntry.glucose = ((NumberFieldCell*)currentEditingField).number;
    }
    glucoseCell.number = self.logEntry.glucose;
    currentEditingField = nil;
    self.navigationItem.rightBarButtonItem.enabled = YES;
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

#pragma mark CategoryViewControllerDelegate

- (void) categoryViewControllerDidSelectCategory:(Category *)category
{
    [self dismissModalViewControllerAnimated:YES];
    self.logEntry.category = category;
}

#pragma mark DoseFieldCellDelegate

- (void)doseDidBeginEditing:(DoseFieldCell*)cell
{
    currentEditingField = cell.doseField;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)doseDidEndEditing:(DoseFieldCell *)cell
{
    if( currentEditingField )
    {
	[self.logEntry setDose:[cell.doseField number] insulinDose:cell.dose];
	if( editingNewEntry )
	{
	    NSIndexPath* path = [self.tableView indexPathForCell:cell];
	    NSIndexPath* next = [NSIndexPath indexPathForRow:path.row+1 inSection:kSectionInsulin];
	    DoseFieldCell* cell = (DoseFieldCell*)[self.tableView cellForRowAtIndexPath:next];
	    if( cell )	// Found a next insulin row
	    {
		[cell.doseField becomeFirstResponder];
		return;
	    }
	}
    }
    cell.dose = cell.dose;

    currentEditingField = nil;
    self.navigationItem.rightBarButtonItem.enabled = YES;
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

#pragma mark TextViewCellDelegate

- (void) textViewCellDidBeginEditing:(TextViewCell*)cell
{
    currentEditingField = (UITextField*)cell.textView;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) textViewCellDidEndEditing:(TextViewCell*)cell
{
    if( currentEditingField )
	self.logEntry.note = cell.text;
    cell.text = self.logEntry.note;

    self.navigationItem.rightBarButtonItem.enabled = YES;
}

@end
