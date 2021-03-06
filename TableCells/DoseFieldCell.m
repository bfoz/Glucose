#import "DoseFieldCell.h"
#import "ManagedInsulinType.h"
#import "Constants.h"

@implementation DoseFieldCell
{
    NSUndoManager*  _undoManager;
}

+ (DoseFieldCell*) cellForInsulinDose:(ManagedInsulinDose*)insulinDose
			accessoryView:(UIView*)accessoryView
			     delegate:(id<DoseFieldCellDelegate>)delegate
			    precision:(unsigned)precision
			    tableView:(UITableView*)tableView
{
    DoseFieldCell* cell = [self cellForInsulinType:insulinDose.insulinType
				     accessoryView:accessoryView
					  delegate:delegate
					 precision:precision
					 tableView:tableView];

    cell.dose = insulinDose;

    return cell;
}

+ (DoseFieldCell*) cellForInsulinType:(ManagedInsulinType*)insulinType
			accessoryView:(UIView*)accessoryView
			     delegate:(id<DoseFieldCellDelegate>)delegate
			    precision:(unsigned)precision
			    tableView:(UITableView*)tableView
{
    DoseFieldCell* cell = (DoseFieldCell*)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass(self)];
    if( !cell )
    {
	cell = [[DoseFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass(self)];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.delegate = delegate;
	cell.doseField.inputAccessoryView = accessoryView;
    }

    cell.insulinType = insulinType;
    cell.precision = precision;

    return cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
    {
	self.selectionStyle = UITableViewCellSelectionStyleNone;

	_doseField = [[NumberField alloc] initWithDelegate:self];
	_doseField.backgroundColor = [UIColor clearColor];
	_doseField.textAlignment = NSTextAlignmentRight;
	_doseField.textColor = [UIColor blueColor];
	_doseField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	_doseField.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
	_doseField.clearButtonMode = UITextFieldViewModeWhileEditing;
	_doseField.placeholder = @"Insulin Dose";

	_typeField = [[UILabel alloc] initWithFrame:CGRectZero];
	_typeField.backgroundColor = [UIColor clearColor];
	_typeField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];

	self.textLabel.backgroundColor = [UIColor clearColor];
	self.textLabel.text = @"New Insulin Dose";
	self.textLabel.textColor = [UIColor lightGrayColor];
	self.textLabel.textAlignment = NSTextAlignmentCenter;

	[self.contentView addSubview:_doseField];
	[self.contentView addSubview:_typeField];
	[self updateHidden];
	[self layoutSubviews];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect insetRect = CGRectInset([self.contentView bounds], kCellLeftOffset, 0);
    const unsigned w = insetRect.size.width/2;
    insetRect.size.width = w;
    _typeField.frame  = insetRect;
    insetRect.origin.x += w;
    _doseField.frame  = insetRect;
}

#pragma mark -

- (void) cancel
{
    [self.undoManager undo];
    [_doseField resignFirstResponder];
}

- (void) save
{
    [self.undoManager removeAllActions];
    [_doseField resignFirstResponder];
}

- (void) updateHidden
{
    self.textLabel.hidden = !(!_doseField.number && !self.insulinType);
    [[[self.contentView subviews] objectAtIndex:0] setHidden:self.textLabel.hidden];
    _doseField.hidden = !self.textLabel.hidden;
    _typeField.hidden = !self.textLabel.hidden;
}

#pragma mark - Accessors

- (void)setDose:(ManagedInsulinDose*)d
{
    // Need to redo layout if dose has changed
    if( _dose != d )
	[self setNeedsLayout];

    _dose = d;
    
    if( !_dose )
	return;

    _doseField.number = d.quantity;
    [self updateHidden];
}

- (void) setInsulinType:(ManagedInsulinType *)insulinType
{
    _insulinType = insulinType;

    // Fake a placeholder type display for the UILabel when no insulin type is set for the row
    if( _insulinType )
    {
	_typeField.text = _insulinType.shortName;
	_typeField.textColor = [UIColor darkTextColor];
    }
    else
    {
	_typeField.text = @"Type";
	_typeField.textColor = [UIColor lightGrayColor];
    }
    [self updateHidden];
}

- (NSNumber*) number
{
    return _doseField.number;
}

- (void) setNumber:(NSNumber*)n
{
    _doseField.number = n;
}

- (int) precision
{
    return _doseField.precision;
}

- (void) setPrecision:(int)p
{
    _doseField.precision = p;
}

// This looks funny because it generates an NSUndoManager if the underlying field
//  control doesn't have one. The only time this should happen is when running tests.
- (NSUndoManager*) undoManager
{
    if( _doseField.undoManager )
	return _doseField.undoManager;
    if( nil == _undoManager )
	_undoManager = [[NSUndoManager alloc] init];
    return _undoManager;
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.undoManager registerUndoWithTarget:self.doseField selector:@selector(setNumber:) object:self.doseField.number];
    if( self.delegate && [self.delegate respondsToSelector:@selector(doseDidBeginEditing:)] )
	[self.delegate doseDidBeginEditing:self];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(doseShouldBeginEditing:)])
	return [self.delegate doseShouldBeginEditing:self];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(doseDidEndEditing:)])
        [self.delegate doseDidEndEditing:self];
}
/*
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.target && [self.target respondsToSelector:@selector(textFieldShouldEndEditing:)])
        return [self.target textFieldShouldEndEditing:textField];
    return YES;
}
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_doseField resignFirstResponder];
    return YES;
}

@end
