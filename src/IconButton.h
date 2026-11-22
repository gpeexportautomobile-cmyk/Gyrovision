#import <UIKit/UIKit.h>

@interface IconButton : UIControl

@property (strong, nonatomic) NSString *symbolName;
@property (strong, nonatomic) UIColor *iconColor;
@property (assign, nonatomic) CGPoint parallaxOffset;

@end