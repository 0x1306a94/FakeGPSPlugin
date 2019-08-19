//
//  ViewController.m
//  FakeGPS
//
//  Created by king on 2019/8/2.
//

#import "ViewController.h"

#import <CoreLocation/CoreLocation.h>

#import <ReactiveObjC/ReactiveObjC.h>

#import "CommonDefs.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *latitudeTextField;
@property (weak, nonatomic) IBOutlet UITextField *longitudeTextField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
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
                NSLog(@"保存成功...");
            }
        }
		return [RACSignal empty];
	}];
	/* clang-format on */

	self.stopButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
		NSNumber *old                  = self.fakeGPSInfo[kFakeStopKey] ?: @NO;
		self.fakeGPSInfo[kFakeStopKey] = @(!self.stopButton.selected);
		if ([self.fakeGPSInfo writeToFile:kFakeGPSFilePath atomically:YES]) {
			[self updateState];
		} else {
			self.fakeGPSInfo[kFakeStopKey] = old;
		}
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
@end
