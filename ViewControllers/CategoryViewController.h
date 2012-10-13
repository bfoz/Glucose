#import "SlidingViewController.h"
#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class	Category;
@class	LogModel;
@protocol CategoryViewControllerDelegate;

@interface CategoryViewController : SlidingViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    LogModel*			model;

    BOOL	didUndo;
	BOOL			dirty;
    Category*	deleteCategory;
    unsigned	deleteRow;
}

@property (nonatomic, unsafe_unretained) id <CategoryViewControllerDelegate>   delegate;
@property (nonatomic, strong) LogModel*				    model;
@property (nonatomic, strong) Category* selectedCategory;

@end

@protocol CategoryViewControllerDelegate <NSObject>

@optional
- (void) categoryViewControllerCreateCategory;
- (void) categoryViewControllerDidDeleteCategory:(Category*)category;
- (void) categoryViewControllerDidSelectCategory:(Category*)category;
- (void) categoryViewControllerDidSelectRestoreDefaults;

@end
