//
//  Applaction.h
//  FakeGPS
//
//  Created by king on 2019/8/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Applaction : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *bundleIdentifier;
@property (nonatomic, strong) UIImage *iconImage;
@property (nonatomic, assign) BOOL on;
@end

NS_ASSUME_NONNULL_END
