#import "EditTextViewController.h"

@interface EditTextViewController () <UITextViewDelegate>

@end

@implementation EditTextViewController
{
    UITextView*	textView;
}

- (id)initWithText:(NSString*)text
{
    self = [super initWithNibName:nil bundle:nil];
    if( self )
    {
	textView = [[UITextView alloc] init];
	textView.text = text;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = textView.text.length ? @"Edit Note" : @"Add a Note";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didTapSaveButton)];

    self.view.backgroundColor = [UIColor whiteColor];

    textView.frame = self.view.bounds;
    textView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
    [self.view addSubview:textView];

    [textView becomeFirstResponder];
}

#pragma mark Accessors

- (NSString*) text
{
    return textView.text;
}

#pragma mark Actions

- (void) didTapCancelButton
{
    [textView resignFirstResponder];
    [self.delegate editTextViewControllerDidFinishWithText:nil];
}

- (void) didTapSaveButton
{
    [textView resignFirstResponder];
    NSString* text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.delegate editTextViewControllerDidFinishWithText:text.length ? text : nil];
}

@end
