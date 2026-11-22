#import <UIKit/UIKit.h>
#import "IconButton.h"

@protocol GlassMenuViewDelegate <NSObject>
- (void)glassMenuView:(GlassMenuView *)menuView didSelectIcon:(IconButton *)icon atIndex:(NSInteger)index;
@end

@interface GlassMenuView : UIView

@property (weak, nonatomic) id<GlassMenuViewDelegate> delegate;

- (void)updateParallaxWithOffset:(CGPoint)offset;

@end