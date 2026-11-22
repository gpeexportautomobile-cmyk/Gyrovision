#import "GyroViewController.h"
#import "GlassMenuView.h"
#import "IconButton.h"

@interface GyroViewController () <GlassMenuViewDelegate>

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) GlassMenuView *menuView;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UILabel *statusLabel;
@property (assign, nonatomic) BOOL motionPermissionGranted;
@property (assign, nonatomic) double lastRoll;
@property (assign, nonatomic) double lastPitch;
@property (assign, nonatomic) double lastYaw;

@end

@implementation GyroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupBackground];
    [self setupStatusLabel];
    [self setupMotionManager];
    [self requestMotionPermission];
}

- (void)setupBackground {
    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.backgroundView.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.05 green:0.05 blue:0.15 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.1 green:0.1 blue:0.25 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.02 green:0.02 blue:0.1 alpha:1.0].CGColor
    ];
    gradient.locations = @[@0.0, @0.5, @1.0];
    [self.backgroundView.layer insertSublayer:gradient atIndex:0];
    
    for (int i = 0; i < 30; i++) {
        UIView *star = [[UIView alloc] initWithFrame:CGRectMake(
            arc4random_uniform((uint32_t)self.view.bounds.size.width),
            arc4random_uniform((uint32_t)self.view.bounds.size.height),
            2 + arc4random_uniform(3), 2 + arc4random_uniform(3)
        )];
        star.backgroundColor = [UIColor whiteColor];
        star.alpha = 0.3 + (arc4random_uniform(70) / 100.0);
        star.layer.cornerRadius = star.bounds.size.width / 2;
        [self.backgroundView addSubview:star];
        
        [UIView animateWithDuration:2.0 + (arc4random_uniform(30) / 10.0)
                              delay:arc4random_uniform(20) / 10.0
                            options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             star.alpha = 0.1;
                         } completion:nil];
    }
    
    [self.view addSubview:self.backgroundView];
}

- (void)setupStatusLabel {
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"Solicitare permisiune mișcare...";
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.alpha = 0.8;
    [self.view addSubview:self.statusLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.statusLabel.heightAnchor constraintEqualToConstant:20]
    ]];
}

- (void)setupMotionManager {
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    self.motionManager.gyroUpdateInterval = 1.0 / 60.0;
}

- (void)requestMotionPermission {
    if (@available(iOS 11.0, *)) {
        [CMMotionActivityManager new];
    }
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Motion error: %@", error);
            return;
        }
        if (motion) {
            self.motionPermissionGranted = YES;
            [self updateStatus:@"Mișcare activată - Inclinați dispozitivul"];
            [self handleDeviceMotion:motion];
        }
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.motionPermissionGranted) {
            [self updateStatus:@"Permisiune mișcare necesară - Verificați Setări > Confidențialitate > Mișcare"];
            [self showPermissionAlert];
        }
    });
}

- (void)showPermissionAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Permisiune Mișcare"
                                                                   message:@"GyroVision are nevoie de acces la senzorii de mișcare pentru navigare 3D și efecte parallax. Activați în Setări > Confidențialitate > Mișcare & Fitness."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Deschide Setări" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateStatus:(NSString *)text {
    self.statusLabel.text = text;
}

- (void)handleDeviceMotion:(CMDeviceMotion *)motion {
    CMAttitude *attitude = motion.attitude;
    
    double roll = attitude.roll;
    double pitch = attitude.pitch;
    double yaw = attitude.yaw;
    
    if (self.lastRoll == 0 && self.lastPitch == 0 && self.lastYaw == 0) {
        self.lastRoll = roll;
        self.lastPitch = pitch;
        self.lastYaw = yaw;
        return;
    }
    
    double deltaRoll = roll - self.lastRoll;
    double deltaPitch = pitch - self.lastPitch;
    double deltaYaw = yaw - self.lastYaw;
    
    self.lastRoll = roll;
    self.lastPitch = pitch;
    self.lastYaw = yaw;
    
    CGFloat maxOffset = 30.0;
    CGFloat xOffset = (CGFloat)(deltaYaw * 50.0);
    CGFloat yOffset = (CGFloat)(deltaPitch * 50.0);
    CGFloat zRotation = (CGFloat)(deltaRoll * 30.0);
    
    xOffset = fmaxf(-maxOffset, fminf(maxOffset, xOffset));
    yOffset = fmaxf(-maxOffset, fminf(maxOffset, yOffset));
    
    [UIView animateWithDuration:0.016 delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.backgroundView.transform = CGAffineTransformMakeTranslation(xOffset, yOffset);
        
        if (self.menuView) {
            CATransform3D transform = CATransform3DIdentity;
            transform.m34 = -1.0 / 500.0;
            transform = CATransform3DRotate(transform, yOffset * 0.01, 1, 0, 0);
            transform = CATransform3DRotate(transform, -xOffset * 0.01, 0, 1, 0);
            transform = CATransform3DRotate(transform, zRotation * 0.005, 0, 0, 1);
            transform = CATransform3DTranslate(transform, xOffset * 0.5, yOffset * 0.5, 0);
            self.menuView.layer.transform = transform;
            
            [self.menuView updateParallaxWithOffset:CGPointMake(xOffset, yOffset)];
        }
    } completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showMenu];
}

- (void)showMenu {
    if (self.menuView) return;
    
    self.menuView = [[GlassMenuView alloc] initWithFrame:CGRectZero];
    self.menuView.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuView.delegate = self;
    self.menuView.alpha = 0;
    self.menuView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [self.view addSubview:self.menuView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.menuView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.menuView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.menuView.widthAnchor constraintEqualToConstant:320],
        [self.menuView.heightAnchor constraintEqualToConstant:480]
    ]];
    
    [UIView animateWithDuration:0.6 delay:0.2 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.menuView.alpha = 1;
        self.menuView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)glassMenuView:(GlassMenuView *)menuView didSelectIcon:(IconButton *)icon atIndex:(NSInteger)index {
    NSString *names[] = {@"Foto", @"Mesaje", @"Setări", @"Muzică", @"Calendar", @"Meteo", @"Note", @"Profil"};
    NSString *name = (index < 8) ? names[index] : [NSString stringWithFormat:@"Aplicație %ld", (long)index + 1];
    
    [self updateStatus:[NSString stringWithFormat:@"Deschis: %@", name]];
    
    CAKeyframeAnimation *pop = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    pop.values = @[@1.0, @1.3, @0.9, @1.0];
    pop.keyTimes = @[@0.0, @0.3, @0.6, @1.0];
    pop.duration = 0.4;
    pop.timingFunction = [CAMediaTimingFunction functionWithName:CAMediaTimingFunctionNameEaseOut];
    [icon.layer addAnimation:pop forKey:@"pop"];
    
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.backgroundView.frame = CGRectMake(0, 0, size.width, size.height);
    } completion:nil];
}

- (void)dealloc {
    [self.motionManager stopDeviceMotionUpdates];
}

@end