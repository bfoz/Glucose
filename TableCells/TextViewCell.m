#import "TextViewCell.h"
#import "Constants.h"

#import "ManagedLogEntry+App.h"

@implementation TextViewCell

@synthesize delegate, dirty, font, placeholder, text;

+ (TextViewCell*) cellForLogEntry:(ManagedLogEntry*)logEntry delegate:(id<TextViewCellDelegate>)delegate inputAccessoryView:(UIView*)inputAccessoryView tableView:(UITableView*)tableView
{
    TextViewCell* cell = (TextViewCell*)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass(self)];
    if( !cell )
    {
	cell = [[TextViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass(self)];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.delegate = delegate;
	cell.placeholder = @"Add a Note";
	cell.textView.inputAccessoryView = inputAccessoryView;
    }

    cell.textLabel.text = logEntry.note;
    cell.text = logEntry.note;

    return cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] )
    {
	dirty = NO;

	self.selectionStyle = UITableViewCellSelectionStyleNone;
	_textView = [[UITextView alloc] initWithFrame:CGRectZero];
	_textView.backgroundColor = [UIColor clearColor];
	_textView.delegate = self;
	[self.contentView addSubview:_textView];

	[self setNeedsLayout];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.textView.frame = self.contentView.bounds;
}

- (void) enablePlaceholder
{
    self.textView.text = placeholder;
    self.textView.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    self.textView.textColor = [UIColor lightGrayColor];
}

#pragma mark Propertes

- (void) setFont:(UIFont*)f
{
    font = f;
}

- (NSString*) text
{
    return self.textView.text;
}

- (void) setText:(NSString*)t
{
    self.textView.text = t;

    if( t && [t length])
    {
	dirty = YES;
	self.textView.font = nil;
	self.textView.textColor = nil;
    }
    else
    {
	dirty = NO;
	[self enablePlaceholder];
    }
}

#pragma mark UITextFieldDelegate

- (BOOL) textViewShouldBeginEditing:(UITextView*)textView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewCellShouldBeginEditing:)])
        return [self.delegate textViewCellShouldBeginEditing:self];
    return YES;
}

- (void) textViewDidBeginEditing:(UITextView *)textView
{
    if( !dirty && [textView hasText])
    {
	textView.text = nil;	// Clear the placeholder text
	textView.font = nil;	// Set the font and color
	textView.textColor = nil;
    }
    if( self.delegate && [self.delegate respondsToSelector:@selector(textViewCellDidBeginEditing:)] )
        [self.delegate textViewCellDidBeginEditing:self];
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
    if( [textView hasText] )
	dirty = YES;
    else
    {
	[self enablePlaceholder];
	dirty = NO;
    }

    if( self.delegate && [self.delegate respondsToSelector:@selector(textViewCellDidEndEditing:)] )
        [self.delegate textViewCellDidEndEditing:self];
}

@end
