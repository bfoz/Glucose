#import <UIKit/UIKit.h>

@class InsulinType;

@interface InsulinDose : NSObject
{
	NSNumber*	dose;
}

@property (nonatomic, strong)	NSNumber*	dose;
@property (nonatomic, strong)	InsulinType*	insulinType;

+ (InsulinDose*)withType:(InsulinType*)t;

@end
