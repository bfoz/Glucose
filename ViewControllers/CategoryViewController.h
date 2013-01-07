#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class	ManagedCategory;
@class	LogModel;
@protocol CategoryViewControllerDelegate;

@interface CategoryViewController : UITableViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    LogModel*			model;

	BOOL			dirty;
    unsigned	deleteRow;
}

@property (nonatomic, unsafe_unretained) id <CategoryViewControllerDelegate>   delegate;
@property (nonatomic, strong) LogModel*				    model;
@property (nonatomic, strong) ManagedCategory* selectedCategory;

@end

@protocol CategoryViewControllerDelegate <NSObject>

@optional
- (void) categoryViewControllerCreateCategory;
- (void) categoryViewControllerDidDeleteCategory:(ManagedCategory*)category;
- (void) categoryViewControllerDidSelectCategory:(ManagedCategory*)category;
- (void) categoryViewControllerDidSelectRestoreDefaults;

@end
