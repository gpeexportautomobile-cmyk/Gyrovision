#import "GlassMenuView.h"

@interface GlassMenuView ()

@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (strong, nonatomic) UIView *glassLayer;
@property (strong, nonatomic) NSMutableArray<IconButton *> *iconButtons;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (assign, nonatomic) CGPoint currentParallaxOffset;
@property (assign, nonatomic) CGPoint targetParallaxOffset;

@end

@implementation GlassMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGlassEffect];
        [self setupIcons];
        [self startParallaxAnimation];
    }
    return self;
}

- (void)setupGlassEffect {
    self.layer.cornerRadius = 32;
    self.layer.masksToBounds = NO;
    self.clipsToBounds = NO;
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blurView.frame = self.bounds;
    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blurView.layer.cornerRadius = 32;
    self.blurView.clipsToBounds = YES;
    [self addSubview:self.blurView];
    
    self.glassLayer = [[UIView alloc] initWithFrame:self.bounds];
    self.glassLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.glassLayer.layer.cornerRadius = 32;
    self.glassLayer.clipsToBounds = YES;
    self.glassLayer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    [self.blurView.contentView addSubview:self.glassLayer];
    
    CAGradientLayer *glassGradient = [CAGradientLayer layer];
    glassGradient.frame = self.bounds;
    glassGradient.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:0.15].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.05].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.02].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.08].CGColor
    ];
    glassGradient.locations = @[@0.0, @0.3, @0.7, @1.0];
    glassGradient.startPoint = CGPointMake(0, 0);
    glassGradient.endPoint = CGPointMake(1, 1);
    [self.glassLayer.layer insertSublayer:glassGradient atIndex:0];
    
    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.frame = self.bounds;
    borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:32].CGPath;
    borderLayer.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.lineWidth = 1.0;
    [self.glassLayer.layer addSublayer:borderLayer];
    
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.4;
    self.layer.shadowRadius = 40;
    self.layer.shadowOffset = CGSizeMake(0, 20);
    
    CALayer *innerGlow = [CALayer layer];
    innerGlow.frame = CGRectInset(self.bounds, -2, -2);
    innerGlow.backgroundColor = [UIColor clearColor].CGColor;
    innerGlow.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
    innerGlow.shadowOpacity = 1.0;
    innerGlow.shadowRadius = 2;
    innerGlow.shadowOffset = CGSizeZero;
    innerGlow.masksToBounds = NO;
    [self.layer insertSublayer:innerGlow atIndex:0];
}

- (void)setupIcons {
    self.iconButtons = [NSMutableArray array];
    
    NSArray *iconConfigs = @[
        @{@"symbol": @"photo.fill", @"color": @[0.9, 0.3, 0.4]},
        @{@"symbol": @"message.fill", @"color": @[0.2, 0.7, 0.9]},
        @{@"symbol": @"gearshape.fill", @"color": @[0.6, 0.6, 0.65]},
        @{@"symbol": @"music.note", @"color": @[0.9, 0.4, 0.9]},
        @{@"symbol": @"calendar", @"color": @[0.9, 0.6, 0.2]},
        @{@"symbol": @"cloud.sun.fill", @"color": @[0.4, 0.8, 1.0]},
        @{@"symbol": @"note.text", @"color": @[0.4, 0.9, 0.5]},
        @{@"symbol": @"person.crop.circle.fill", @"color": @[0.8, 0.5, 0.9]}
    ];
    
    CGFloat iconSize = 72;
    CGFloat spacing = 20;
    CGFloat cols = 4;
    CGFloat rows = 2;
    CGFloat totalWidth = cols * iconSize + (cols - 1) * spacing;
    CGFloat totalHeight = rows * iconSize + (rows - 1) * spacing;
    CGFloat startX = (320 - totalWidth) / 2;
    CGFloat startY = (480 - totalHeight) / 2 + 20;
    
    for (NSInteger i = 0; i < iconConfigs.count; i++) {
        NSDictionary *config = iconConfigs[i];
        NSInteger col = i % (NSInteger)cols;
        NSInteger row = i / (NSInteger)cols;
        
        CGFloat x = startX + col * (iconSize + spacing);
        CGFloat y = startY + row * (iconSize + spacing);
        
        IconButton *icon = [[IconButton alloc] initWithFrame:CGRectMake(x, y, iconSize, iconSize)];
        icon.tag = i;
        icon.symbolName = config[@"symbol"];
        NSArray *colorArray = config[@"color"];
        icon.iconColor = [UIColor colorWithRed:colorArray[0].floatValue green:colorArray[1].floatValue blue:colorArray[2].floatValue alpha:1.0];
        [icon addTarget:self action:@selector(iconTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.glassLayer addSubview:icon];
        [self.iconButtons addObject:icon];
        
        icon.transform = CGAffineTransformMakeScale(0.5, 0.5);
        icon.alpha = 0;
        [UIView animateWithDuration:0.5 delay:0.1 + i * 0.05 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            icon.transform = CGAffineTransformIdentity;
            icon.alpha = 1;
        } completion:nil];
    }
}

- (void)startParallaxAnimation {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateParallaxFrame)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)updateParallaxFrame {
    CGFloat factor = 0.15;
    self.currentParallaxOffset.x += (self.targetParallaxOffset.x - self.currentParallaxOffset.x) * factor;
    self.currentParallaxOffset.y += (self.targetParallaxOffset.y - self.currentParallaxOffset.y) * factor;
    
    for (IconButton *icon in self.iconButtons) {
        CGFloat depthFactor = 0.3 + (icon.tag % 3) * 0.15;
        CGFloat xOffset = self.currentParallaxOffset.x * depthFactor;
        CGFloat yOffset = self.currentParallaxOffset.y * depthFactor;
        icon.parallaxOffset = CGPointMake(xOffset, yOffset);
    }
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / 800.0;
    transform = CATransform3DRotate(transform, self.currentParallaxOffset.y * 0.002, 1, 0, 0);
    transform = CATransform3DRotate(transform, -self.currentParallaxOffset.x * 0.002, 0, 1, 0);
    transform = CATransform3DTranslate(transform, self.currentParallaxOffset.x * 0.1, self.currentParallaxOffset.y * 0.1, 0);
    self.glassLayer.layer.transform = transform;
}

- (void)updateParallaxWithOffset:(CGPoint)offset {
    self.targetParallaxOffset = CGPointMake(offset.x * 0.5, offset.y * 0.5);
}

- (void)iconTapped:(IconButton *)sender {
    if ([self.delegate respondsToSelector:@selector(glassMenuView:didSelectIcon:atIndex:)]) {
        [self.delegate glassMenuView:self didSelectIcon:sender atIndex:sender.tag];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.blurView.frame = self.bounds;
    self.glassLayer.frame = self.bounds;
}

- (void)dealloc {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

@end