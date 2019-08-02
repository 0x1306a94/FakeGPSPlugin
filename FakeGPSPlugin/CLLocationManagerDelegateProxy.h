//
//  CLLocationManagerDelegateProxy.h
//  FakeGPS-Plugin
//
//  Created by king on 2019/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLLocationManagerDelegate;

@interface CLLocationManagerDelegateProxy : NSProxy <CLLocationManagerDelegate>

+ (instancetype)proxyWith:(id<CLLocationManagerDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
