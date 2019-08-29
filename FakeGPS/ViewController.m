//
//  ViewController.m
//  FakeGPS
//
//  Created by king on 2019/8/2.
//

#import "ViewController.h"

#import <CoreLocation/CoreLocation.h>

#import <ReactiveObjC/ReactiveObjC.h>

#import <MBProgressHUD/MBProgressHUD.h>

#import "ApplactionHelper.h"
#import "CommonDefs.h"

#import "AppListViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *latitudeTextField;
@property (weak, nonatomic) IBOutlet UITextField *longitudeTextField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *companyButton;
@property (weak, nonatomic) IBOutlet UIButton *appListButton;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *fakeGPSInfo;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.fakeGPSInfo = [[NSMutableDictionary<NSString *, id> alloc] initWithContentsOfFile:kFakeGPSFilePath];
    if (!self.fakeGPSInfo) {
        self.fakeGPSInfo               = [NSMutableDictionary<NSString *, id> dictionary];
        self.fakeGPSInfo[kFakeStopKey] = @NO;
    }
    [self updateState];

    @weakify(self);
    NSArray<__kindof RACSignal *> *combineLatest = @[
        self.latitudeTextField.rac_textSignal,
        self.longitudeTextField.rac_textSignal,
    ];

    /* clang-format off */
    RACSignal<NSNumber *> *enableSiganl = [RACSignal combineLatest:combineLatest reduce:^id _Nonnull(NSString *latitude, NSString *longitude){
        if (latitude.length == 0 || longitude.length == 0) return @NO;
        CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        if (CLLocationCoordinate2DIsValid(coor)) return @YES;
        return @NO;
    }];
    /* clang-format on */

    /* clang-format off */
    self.saveButton.rac_command = [[RACCommand alloc] initWithEnabled:enableSiganl signalBlock:^RACSignal *_Nonnull(id _Nullable input) {
        @strongify(self);
        NSString *latitude = self.latitudeTextField.text;
        NSString *longitude = self.longitudeTextField.text;
        CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        if (CLLocationCoordinate2DIsValid(coor)) {
            self.fakeGPSInfo[kFakeLatitudeKey] = @(coor.latitude);
            self.fakeGPSInfo[kFakeLongitudeKey] = @(coor.longitude);
            if ([self.fakeGPSInfo writeToFile:kFakeGPSFilePath atomically:YES]) {
                [self toast:@"已保存指定位置"];
            }
        }
        return [RACSignal empty];
    }];
    /* clang-format on */

    self.stopButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
        @strongify(self);
        NSNumber *old                  = self.fakeGPSInfo[kFakeStopKey] ?: @NO;
        BOOL new                       = !self.stopButton.selected;
        self.fakeGPSInfo[kFakeStopKey] = @(new);
        if ([self.fakeGPSInfo writeToFile:kFakeGPSFilePath atomically:YES]) {
            [self updateState];
            [self toast:(new ? @"已停止虚拟定位" : @"已打开虚拟定位")];
        } else {
            self.fakeGPSInfo[kFakeStopKey] = old;
        }
        return [RACSignal empty];
    }];

    self.companyButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
        @strongify(self);
        self.fakeGPSInfo[kFakeLatitudeKey]  = @(30.546663);
        self.fakeGPSInfo[kFakeLongitudeKey] = @(104.063318);
        self.fakeGPSInfo[kFakeStopKey]      = @NO;
        if ([self.fakeGPSInfo writeToFile:kFakeGPSFilePath atomically:YES]) {
            [self toast:@"已保存公司位置"];
        }
        return [RACSignal empty];
    }];

    self.appListButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
        @strongify(self);
        AppListViewController *vc = [[AppListViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
        return [RACSignal empty];
    }];
}

- (void)updateState {
    if (!self.fakeGPSInfo) {
        self.fakeGPSInfo = [NSMutableDictionary<NSString *, id> dictionary];
        [self.stopButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.stopButton setTitle:@"Start" forState:UIControlStateHighlighted | UIControlStateSelected];
        self.stopButton.selected = NO;
    } else {
        BOOL stop       = [self.fakeGPSInfo[kFakeStopKey] boolValue];
        NSString *title = stop ? @"Start" : @"Stop";
        [self.stopButton setTitle:title forState:UIControlStateNormal];
        [self.stopButton setTitle:title forState:UIControlStateHighlighted | UIControlStateSelected];
        self.stopButton.selected = stop;
    }
}

- (void)toast:(NSString *)message {
    MBProgressHUD *hud            = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.bezelView.style           = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.backgroundColor = [UIColor blackColor];
    hud.contentColor              = [UIColor whiteColor];
    hud.animationType             = MBProgressHUDAnimationFade;
    hud.mode                      = MBProgressHUDModeText;
    hud.detailsLabel.text         = message;
    [hud hideAnimated:YES afterDelay:3.0];
}

@end

