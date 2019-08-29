//
//  AppListTableViewCell.h
//  FakeGPS
//
//  Created by king on 2019/8/29.
//

#import <UIKit/UIKit.h>

/* System */

/* ViewController */

/* View */

/* Model */

/* Util */

/* NetWork InterFace */

/* Vender */

NS_ASSUME_NONNULL_BEGIN

@interface AppListTableViewCell : UITableViewCell
@property (weak, nonatomic, readonly) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic, readonly) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic, readonly) IBOutlet UILabel *bundleIdentifierLabel;
@property (weak, nonatomic, readonly) IBOutlet UISwitch *stateSwitch;
@end

NS_ASSUME_NONNULL_END

