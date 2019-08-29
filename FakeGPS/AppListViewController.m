//
//  AppListViewController.m
//  FakeGPS
//
//  Created by king on 2019/8/29.
//

#import "AppListViewController.h"

/* System */
#import <notify.h>
/* ViewController */

/* View */
#import "AppListTableViewCell.h"
/* Model */

/* Util */
#import "Applaction.h"
#import "ApplactionHelper.h"
#import "CommonDefs.h"

/* NetWork InterFace */

/* Vender */
#import <ReactiveObjC/ReactiveObjC.h>

@interface AppListViewController () <UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray<Applaction *> *installedApps;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) RACCommand *readInstalledAppsCommand;
@end

@implementation AppListViewController

#if DEBUG
- (void)dealloc {
    NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
}
#endif

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
    [self addEventAction];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.readInstalledAppsCommand execute:nil];
}

#pragma mark - initial Methods
- (void)commonInit {
    self.view.backgroundColor = [UIColor whiteColor];

    UINib *nib = [UINib nibWithNibName:NSStringFromClass(AppListTableViewCell.class) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:NSStringFromClass(AppListTableViewCell.class)];

    self.tableView.rowHeight       = 80;
    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];

    [self addSubViews];
    [self addSubViewConstraints];
}

#pragma mark - add subview
- (void)addSubViews {
    [self.view addSubview:self.indicatorView];
    [self.view bringSubviewToFront:self.indicatorView];
}

#pragma mark - layout
- (void)addSubViewConstraints {
    self.indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.indicatorView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.indicatorView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

#pragma mark - event action
- (void)addEventAction {
    @weakify(self);
    [[self.readInstalledAppsCommand.executing deliverOnMainThread] subscribeNext:^(NSNumber *_Nullable x) {
        @strongify(self);
        x.boolValue ? [self.indicatorView startAnimating] : [self.indicatorView stopAnimating];
    }];

    [(RACSignal<NSArray<Applaction *> *> *)[[[self.readInstalledAppsCommand executionSignals] switchToLatest] deliverOnMainThread] subscribeNext:^(NSArray<Applaction *> *_Nullable x) {
        @strongify(self);
        self.installedApps = x;
        [self.tableView reloadData];
    }];
}

#pragma mark - private method

#pragma mark - public Method

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.installedApps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppListTableViewCell *cell      = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(AppListTableViewCell.class)];
    Applaction *app                 = self.installedApps[indexPath.row];
    cell.iconImageView.image        = app.iconImage;
    cell.nameLabel.text             = [app.name stringByReplacingOccurrencesOfString:@".app" withString:@""];
    cell.bundleIdentifierLabel.text = app.bundleIdentifier;
    cell.stateSwitch.on             = app.on;

    @weakify(self);
    [(RACSignal<UISwitch *> *)[[cell.stateSwitch rac_signalForControlEvents:UIControlEventValueChanged] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(UISwitch *_Nullable x) {
        @strongify(self);
        if ([[NSFileManager defaultManager] fileExistsAtPath:kInjectionPlistPath]) {
            NSMutableDictionary *injectionInfo                     = [[NSDictionary dictionaryWithContentsOfFile:kInjectionPlistPath] mutableCopy];
            NSMutableArray<NSString *> *injectionBundleIdentifiers = [[injectionInfo valueForKeyPath:@"Filter.Bundles"] mutableCopy];
            if (x.on && ![injectionBundleIdentifiers containsObject:app.bundleIdentifier]) {
                // 添加
                [injectionBundleIdentifiers addObject:app.bundleIdentifier];
            } else if (!x.on && [injectionBundleIdentifiers containsObject:app.bundleIdentifier]) {
                // 移除
                [injectionBundleIdentifiers removeObject:app.bundleIdentifier];
            }
            NSMutableDictionary *filterDict = [injectionInfo[@"Filter"] mutableCopy];
            [filterDict setObject:injectionBundleIdentifiers forKey:@"Bundles"];
            [injectionInfo setObject:filterDict forKey:@"Filter"];
            if ([injectionInfo writeToFile:kInjectionTempPlistPath atomically:YES]) {
                app.on = x.on;
                [self.tableView reloadData];

                NSString *title    = [NSString stringWithFormat:@"重启 %@ 后生效", app.name];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];

                notify_post(kReloadDynamicLibrariesConfiguration);
            }
        }
    }];
    return cell;
}
#pragma mark - UITableViewDelegate
//...(多个代理方法依次往下写)

#pragma mark - getters and setters
- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView                  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

- (RACCommand *)readInstalledAppsCommand {
    if (!_readInstalledAppsCommand) {
        _readInstalledAppsCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
            return [[RACSignal createSignal:^RACDisposable *_Nullable(id<RACSubscriber> _Nonnull subscriber) {
                [subscriber sendNext:[ApplactionHelper readInstalledApps]];
                [subscriber sendCompleted];
                return nil;
            }] subscribeOn:[RACScheduler scheduler]];
        }];
    }
    return _readInstalledAppsCommand;
}
@end

