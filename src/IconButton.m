#import "IconButton.h"

@interface IconButton ()

@property (strong, nonatomic) CAShapeLayer *iconLayer;
@property (strong, nonatomic) CAGradientLayer *backgroundGradient;
@property (strong, nonatomic) CALayer *glowLayer;
@property (strong, nonatomic) CAShapeLayer *borderLayer;
@property (strong, nonatomic) UIView *highlightView;

@end

@implementation IconButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (void)setupLayers {
    self.layer.cornerRadius = self.bounds.size.width / 2;
    self.layer.masksToBounds = NO;
    
    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.frame = self.bounds;
    self.backgroundGradient.cornerRadius = self.bounds.size.width / 2;
    self.backgroundGradient.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:0.15].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.05].CGColor
    ];
    self.backgroundGradient.locations = @[@0.0, @1.0];
    self.backgroundGradient.startPoint = CGPointMake(0, 0);
    self.backgroundGradient.endPoint = CGPointMake(1, 1);
    [self.layer insertSublayer:self.backgroundGradient atIndex:0];
    
    self.glowLayer = [CALayer layer];
    self.glowLayer.frame = CGRectInset(self.bounds, -8, -8);
    self.glowLayer.cornerRadius = self.bounds.size.width / 2 + 8;
    self.glowLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.glowLayer.shadowOpacity = 0;
    self.glowLayer.shadowRadius = 20;
    self.glowLayer.shadowOffset = CGSizeZero;
    [self.layer insertSublayer:self.glowLayer atIndex:0];
    
    self.borderLayer = [CAShapeLayer layer];
    self.borderLayer.frame = self.bounds;
    self.borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.bounds.size.width/2].CGPath;
    self.borderLayer.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    self.borderLayer.fillColor = [UIColor clearColor].CGColor;
    self.borderLayer.lineWidth = 1.0;
    [self.layer addSublayer:self.borderLayer];
    
    self.iconLayer = [CAShapeLayer layer];
    self.iconLayer.frame = CGRectInset(self.bounds, self.bounds.size.width * 0.25, self.bounds.size.height * 0.25);
    self.iconLayer.fillColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:self.iconLayer];
    
    self.highlightView = [[UIView alloc] initWithFrame:self.bounds];
    self.highlightView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.highlightView.layer.cornerRadius = self.bounds.size.width / 2;
    self.highlightView.alpha = 0;
    [self addSubview:self.highlightView];
    
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.3;
    self.layer.shadowRadius = 12;
    self.layer.shadowOffset = CGSizeMake(0, 6);
}

- (void)setSymbolName:(NSString *)symbolName {
    _symbolName = symbolName;
    [self updateIconPath];
}

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    self.glowLayer.shadowColor = iconColor.CGColor;
    self.iconLayer.fillColor = [UIColor whiteColor].CGColor;
    
    CAGradientLayer *colorOverlay = [CAGradientLayer layer];
    colorOverlay.frame = self.iconLayer.bounds;
    colorOverlay.colors = @[
        (id)iconColor.CGColor,
        (id)[iconColor colorWithAlphaComponent:0.7].CGColor
    ];
    colorOverlay.startPoint = CGPointMake(0, 0);
    colorOverlay.endPoint = CGPointMake(1, 1);
    self.iconLayer.backgroundColor = [UIColor clearColor].CGColor;
}

- (void)updateIconPath {
    if (!self.symbolName) return;
    
    UIBezierPath *path = [self pathForSymbol:self.symbolName inRect:self.iconLayer.bounds];
    self.iconLayer.path = path.CGPath;
}

- (UIBezierPath *)pathForSymbol:(NSString *)name inRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat w = rect.size.width;
    CGFloat h = rect.size.height;
    CGFloat cx = rect.origin.x + w/2;
    CGFloat cy = rect.origin.y + h/2;
    CGFloat r = MIN(w, h) * 0.4;
    
    if ([name hasPrefix:@"photo"]) {
        CGFloat inset = r * 0.3;
        [path moveToPoint:CGPointMake(cx - r, cy - r + inset)];
        [path addLineToPoint:CGPointMake(cx - r, cy + r - inset)];
        [path addLineToPoint:CGPointMake(cx + r, cy + r - inset)];
        [path addLineToPoint:CGPointMake(cx + r, cy - r + inset)];
        [path closePath];
        [path moveToPoint:CGPointMake(cx - r * 0.3, cy - r * 0.2)];
        [path addArcWithCenter:CGPointMake(cx - r * 0.3, cy - r * 0.2) radius:r * 0.15 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    } else if ([name hasPrefix:@"message"]) {
        [path moveToPoint:CGPointMake(cx - r, cy - r * 0.5)];
        [path addLineToPoint:CGPointMake(cx + r, cy - r * 0.5)];
        [path addLineToPoint:CGPointMake(cx + r, cy + r * 0.5)];
        [path addLineToPoint:CGPointMake(cx + r * 0.3, cy + r * 0.5)];
        [path addLineToPoint:CGPointMake(cx, cy + r)];
        [path addLineToPoint:CGPointMake(cx - r * 0.3, cy + r * 0.5)];
        [path addLineToPoint:CGPointMake(cx - r, cy + r * 0.5)];
        [path closePath];
    } else if ([name hasPrefix:@"gear"] || [name hasPrefix:@"gearshape"]) {
        NSInteger teeth = 8;
        for (int i = 0; i < teeth; i++) {
            CGFloat angle = (M_PI * 2 / teeth) * i;
            CGFloat angleNext = (M_PI * 2 / teeth) * (i + 1);
            CGFloat angleMid = (angle + angleNext) / 2;
            
            CGPoint outer1 = CGPointMake(cx + cos(angle) * r, cy + sin(angle) * r);
            CGPoint outer2 = CGPointMake(cx + cos(angleNext) * r, cy + sin(angleNext) * r);
            CGPoint inner1 = CGPointMake(cx + cos(angleMid) * r * 0.6, cy + sin(angleMid) * r * 0.6);
            
            if (i == 0) [path moveToPoint:outer1];
            [path addLineToPoint:outer2];
            [path addLineToPoint:inner1];
        }
        [path closePath];
        [path moveToPoint:CGPointMake(cx + r * 0.25, cy)];
        [path addArcWithCenter:CGPointMake(cx, cy) radius:r * 0.25 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    } else if ([name hasPrefix:@"music"]) {
        [path moveToPoint:CGPointMake(cx - r * 0.3, cy - r)];
        [path addLineToPoint:CGPointMake(cx - r * 0.3, cy + r)];
        [path addLineToPoint:CGPointMake(cx - r * 0.1, cy + r)];
        [path addLineToPoint:CGPointMake(cx - r * 0.1, cy - r)];
        [path closePath];
        [path moveToPoint:CGPointMake(cx + r * 0.1, cy - r)];
        [path addLineToPoint:CGPointMake(cx + r * 0.1, cy + r)];
        [path addLineToPoint:CGPointMake(cx + r * 0.3, cy + r)];
        [path addLineToPoint:CGPointMake(cx + r * 0.3, cy - r)];
        [path closePath];
        [path moveToPoint:CGPointMake(cx + r * 0.4, cy - r)];
        [path addQuadCurveToPoint:CGPointMake(cx + r * 0.8, cy) controlPoint:CGPointMake(cx + r * 0.9, cy - r * 0.5)];
        [path addQuadCurveToPoint:CGPointMake(cx + r * 0.4, cy + r) controlPoint:CGPointMake(cx + r * 0.9, cy + r * 0.5)];
    } else if ([name hasPrefix:@"calendar"]) {
        [path moveToPoint:CGPointMake(cx - r, cy - r)];
        [path addLineToPoint:CGPointMake(cx + r, cy - r)];
        [path addLineToPoint:CGPointMake(cx + r, cy + r)];
        [path addLineToPoint:CGPointMake(cx - r, cy + r)];
        [path closePath];
        [path moveToPoint:CGPointMake(cx - r, cy - r * 0.3)];
        [path addLineToPoint:CGPointMake(cx + r, cy - r * 0.3)];
        [path moveToPoint:CGPointMake(cx - r * 0.5, cy - r)];
        [path addLineToPoint:CGPointMake(cx - r * 0.5, cy - r * 0.3)];
        [path moveToPoint:CGPointMake(cx + r * 0.5, cy - r)];
        [path addLineToPoint:CGPointMake(cx + r * 0.5, cy - r * 0.3)];
        [path moveToPoint:CGPointMake(cx - r * 0.3, cy)];
        [path addLineToPoint:CGPointMake(cx + r * 0.3, cy)];
    } else if ([name hasPrefix:@"cloud"]) {
        [path moveToPoint:CGPointMake(cx - r, cy)];
        [path addQuadCurveToPoint:CGPointMake(cx, cy - r) controlPoint:CGPointMake(cx - r, cy - r)];
        [path addQuadCurveToPoint:CGPointMake(cx + r, cy) controlPoint:CGPointMake(cx + r, cy - r)];
        [path addQuadCurveToPoint:CGPointMake(cx, cy + r * 0.3) controlPoint:CGPointMake(cx + r, cy + r * 0.3)];
        [path addQuadCurveToPoint:CGPointMake(cx - r, cy) controlPoint:CGPointMake(cx - r, cy + r * 0.3)];
        [path moveToPoint:CGPointMake(cx + r * 0.2, cy - r * 0.2)];
        [path addArcWithCenter:CGPointMake(cx + r * 0.2, cy - r * 0.2) radius:r * 0.15 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    } else if ([name hasPrefix:@"note"]) {
        [path moveToPoint:CGPointMake(cx - r * 0.7, cy - r)];
        [path addLineToPoint:CGPointMake(cx + r * 0.7, cy - r)];
        [path addLineToPoint:CGPointMake(cx + r * 0.7, cy + r)];
        [path addLineToPoint:CGPointMake(cx - r * 0.7, cy + r)];
        [path closePath];
        for (int i = 0; i < 3; i++) {
            CGFloat y = cy - r * 0.3 + i * r * 0.3;
            [path moveToPoint:CGPointMake(cx - r * 0.5, y)];
            [path addLineToPoint:CGPointMake(cx + r * 0.5, y)];
        }
    } else if ([name hasPrefix:@"person"]) {
        [path moveToPoint:CGPointMake(cx, cy - r * 0.7)];
        [path addArcWithCenter:CGPointMake(cx, cy - r * 0.7) radius:r * 0.35 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        [path moveToPoint:CGPointMake(cx - r, cy + r * 0.5)];
        [path addQuadCurveToPoint:CGPointMake(cx + r, cy + r * 0.5) controlPoint:CGPointMake(cx, cy + r * 1.2)];
    } else {
        [path addArcWithCenter:CGPointMake(cx, cy) radius:r startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    }
    
    return path;
}

- (void)setParallaxOffset:(CGPoint)parallaxOffset {
    _parallaxOffset = parallaxOffset;
    self.iconLayer.transform = CATransform3DMakeTranslation(parallaxOffset.x * 0.5, parallaxOffset.y * 0.5, 10);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundGradient.frame = self.bounds;
    self.backgroundGradient.cornerRadius = self.bounds.size.width / 2;
    self.borderLayer.frame = self.bounds;
    self.borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.bounds.size.width/2].CGPath;
    self.glowLayer.frame = CGRectInset(self.bounds, -8, -8);
    self.glowLayer.cornerRadius = self.bounds.size.width / 2 + 8;
    self.highlightView.frame = self.bounds;
    self.highlightView.layer.cornerRadius = self.bounds.size.width / 2;
    self.iconLayer.frame = CGRectInset(self.bounds, self.bounds.size.width * 0.25, self.bounds.size.height * 0.25);
    [self updateIconPath];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [UIView animateWithDuration:0.1 animations:^{
        self.highlightView.alpha = 1;
        self.transform = CGAffineTransformMakeScale(0.95, 0.95);
        self.glowLayer.shadowOpacity = 0.6;
    }];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.highlightView.alpha = 0;
        self.transform = CGAffineTransformIdentity;
        self.glowLayer.shadowOpacity = 0;
    } completion:nil];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [UIView animateWithDuration:0.2 animations:^{
        self.highlightView.alpha = 0;
        self.transform = CGAffineTransformIdentity;
        self.glowLayer.shadowOpacity = 0;
    }];
}

@end