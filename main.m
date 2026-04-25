#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>

// ==========================================
// COMPONENT 1: VẼ VÒNG TRÒN
// ==========================================
@interface HUDCircleView : UIView
@property (nonatomic, strong) CAShapeLayer *bgLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@end

@implementation HUDCircleView
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat radius = frame.size.width / 2.0 - 5;
        CGPoint center = CGPointMake(frame.size.width / 2.0, frame.size.width / 2.0);
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];

        self.bgLayer = [CAShapeLayer layer];
        self.bgLayer.path = circlePath.CGPath;
        self.bgLayer.fillColor = [UIColor clearColor].CGColor;
        self.bgLayer.strokeColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
        self.bgLayer.lineWidth = 4.0;
        [self.layer addSublayer:self.bgLayer];

        self.progressLayer = [CAShapeLayer layer];
        self.progressLayer.path = circlePath.CGPath;
        self.progressLayer.fillColor = [UIColor clearColor].CGColor;
        self.progressLayer.strokeColor = [UIColor greenColor].CGColor;
        self.progressLayer.lineWidth = 4.0;
        self.progressLayer.strokeEnd = 0.0; 
        self.progressLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:self.progressLayer];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];

        self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(-10, frame.size.width + 2, frame.size.width + 20, 20)];
        self.valueLabel.textColor = [UIColor whiteColor];
        self.valueLabel.font = [UIFont boldSystemFontOfSize:11];
        self.valueLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.valueLabel];
    }
    return self;
}
- (void)updateWithProgress:(CGFloat)progress valueText:(NSString *)text {
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;
    self.progressLayer.strokeEnd = progress;
    CGFloat hue = (1.0 - progress) * 0.33; 
    UIColor *dynColor = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
    self.progressLayer.strokeColor = dynColor.CGColor;
    self.valueLabel.text = text;
}
@end

// ==========================================
// COMPONENT 2: MÀN HÌNH CHÍNH CỦA APP
// ==========================================
@interface RootViewController : UIViewController
@property (nonatomic, strong) UIView *hudPanel; 
@property (nonatomic, strong) UILabel *fpsTitle;
@property (nonatomic, strong) UILabel *fpsValue;
@property (nonatomic, strong) HUDCircleView *cpuView;
@property (nonatomic, strong) HUDCircleView *ramView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@end

@implementation RootViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0]; // Nền app màu đen ngầu lòi
    
    // Căn giữa bảng HUD
    self.hudPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 185, 75)];
    self.hudPanel.center = self.view.center;
    self.hudPanel.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.hudPanel.layer.cornerRadius = 15;
    self.hudPanel.layer.masksToBounds = YES;
    [self.view addSubview:self.hudPanel];

    self.fpsTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 50, 15)];
    self.fpsTitle.text = @"FPS";
    self.fpsTitle.textColor = [UIColor lightGrayColor];
    self.fpsTitle.font = [UIFont boldSystemFontOfSize:12];
    self.fpsTitle.textAlignment = NSTextAlignmentCenter;
    [self.hudPanel addSubview:self.fpsTitle];

    self.fpsValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 50, 30)];
    self.fpsValue.textColor = [UIColor greenColor];
    self.fpsValue.font = [UIFont boldSystemFontOfSize:22];
    self.fpsValue.textAlignment = NSTextAlignmentCenter;
    [self.hudPanel addSubview:self.fpsValue];

    self.cpuView = [[HUDCircleView alloc] initWithFrame:CGRectMake(70, 10, 40, 40) title:@"CPU"];
    [self.hudPanel addSubview:self.cpuView];

    self.ramView = [[HUDCircleView alloc] initWithFrame:CGRectMake(130, 10, 40, 40) title:@"RAM"];
    [self.hudPanel addSubview:self.ramView];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTime == 0) { self.lastTime = link.timestamp; return; }
    self.count++;
    NSTimeInterval delta = link.timestamp - self.lastTime;
    
    if (delta >= 1.0) {
        double fps = self.count / delta;
        self.count = 0; self.lastTime = link.timestamp;
        self.fpsValue.text = [NSString stringWithFormat:@"%.0f", fps];

        struct mach_task_basic_info info;
        mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
        kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
        double ramMB = (kerr == KERN_SUCCESS) ? (info.resident_size / 1024.0 / 1024.0) : 0;
        [self.ramView updateWithProgress:(ramMB / 6144.0) valueText:[NSString stringWithFormat:@"%.0f MB", ramMB]];

        thread_array_t thread_list; mach_msg_type_number_t thread_count;
        thread_info_data_t thinfo; mach_msg_type_number_t thread_info_count; thread_basic_info_t basic_info_th;
        kerr = task_threads(mach_task_self(), &thread_list, &thread_count);
        float total_cpu = 0;
        if (kerr == KERN_SUCCESS) {
            for (int j = 0; j < thread_count; j++) {
                thread_info_count = THREAD_INFO_MAX;
                kerr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
                if (kerr == KERN_SUCCESS) {
                    basic_info_th = (thread_basic_info_t)thinfo;
                    if (!(basic_info_th->flags & TH_FLAGS_IDLE)) total_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
                }
            }
            vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
        }
        
        NSUInteger numCores = [[NSProcessInfo processInfo] activeProcessorCount];
        float normalized_cpu = total_cpu / numCores;
        if (normalized_cpu > 100.0) normalized_cpu = 100.0; 
        [self.cpuView updateWithProgress:(normalized_cpu / 100.0) valueText:[NSString stringWithFormat:@"%.0f%%", normalized_cpu]];
    }
}
@end

// ==========================================
// COMPONENT 3: VÒNG ĐỜI ỨNG DỤNG (APP DELEGATE)
// ==========================================
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[RootViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

// ==========================================
// ENTRY POINT (CỔNG CHÍNH VÀO APP)
// ==========================================
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
