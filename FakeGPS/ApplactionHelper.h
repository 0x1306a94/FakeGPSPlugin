//
//  ApplactionHelper.h
//  FakeGPS
//
//  Created by king on 2019/8/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Applaction;

@interface ApplactionHelper : NSObject
+ (NSArray<Applaction *> *)readInstalledApps;
@end

NS_ASSUME_NONNULL_END

