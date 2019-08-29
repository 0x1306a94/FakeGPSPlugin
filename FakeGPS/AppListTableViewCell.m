//
//  AppListTableViewCell.m
//  FakeGPS
//
//  Created by king on 2019/8/29.
//

#import "AppListTableViewCell.h"

/* System */

/* ViewController */

/* View */

/* Model */

/* Util */

/* NetWork InterFace */

/* Vender */

@interface AppListTableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *bundleIdentifierLabel;
@property (weak, nonatomic) IBOutlet UISwitch *stateSwitch;
@end

@implementation AppListTableViewCell

#if DEBUG
- (void)dealloc {
    NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
}
#endif

#pragma mark - life cycle
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
}

#pragma mark - initial Methods
- (void)commonInit {
    /*custom view u want draw in here*/
    self.contentView.backgroundColor       = [UIColor whiteColor];
    self.selectionStyle                    = UITableViewCellSelectionStyleNone;
    self.iconImageView.layer.cornerRadius  = 10;
    self.iconImageView.layer.masksToBounds = YES;
    [self addSubViews];
    [self addSubViewConstraints];
}

#pragma mark - add subview
- (void)addSubViews {
}

#pragma mark - layout
- (void)addSubViewConstraints {
}

#pragma mark - private method

#pragma mark - public method

#pragma mark - getters and setters

@end

