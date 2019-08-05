//
//  FakeGPS_Plugin.mm
//  FakeGPS-Plugin
//
//  Created by king on 2019/8/2.
//  Copyright (c) 2019 ___ORGANIZATIONNAME___. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import "CaptainHook/CaptainHook.h"
#import "Aspects.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#include <notify.h>  // not required; for examples only

#ifdef DEBUG
#define LOG(fmt, ...) NSLog((@"fake gps: " fmt), ##__VA_ARGS__);
#else
#define LOG(...);
#endif

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()

//CHDeclareClass(CLLocation)
CHDeclareClass(CLLocationManager)

//CHOptimizedMethod0(self, CLLocationCoordinate2D, CLLocation, coordinate) {
//    //    CLLocationCoordinate2D orign = CHSuper0(CLLocation, coordinate);
//    CLLocationCoordinate2D orign = CLLocationCoordinate2DMake(35.680723, 103.851502);
//    NSLog(@"hook_gps: longitude:%f  latitude:%f", orign.longitude, orign.latitude);
//    return orign;
//}

CHOptimizedMethod1(self, void, CLLocationManager, setDelegate, id<CLLocationManagerDelegate>, delegate) {
    LOG(@"CLLocationManager delegate -> %@", self);
    CHSuper1(CLLocationManager, setDelegate, delegate);
    if (delegate) {
        [(NSObject *)delegate aspect_hookSelector:@selector(locationManager:didUpdateLocations:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
            LOG(@"locationManager:didUpdateLocations: arguments -> %@", aspectInfo.arguments);
            NSArray<CLLocation *> *fakeLocations = @[[[CLLocation alloc] initWithLatitude:35.680723 longitude:103.851502]];
            [aspectInfo.originalInvocation setArgument:&fakeLocations atIndex:3];
        } error:nil];
    }
}

static void WillEnterForeground(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    // not required; for example only
    LOG(@"com.0x1306a94.hook-gps: %s", __FUNCTION__);
}

static void ExternallyPostedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    // not required; for example only
}

CHConstructor  // code block that runs immediately upon load
{
    @autoreleasepool {
        // listen for local notification (not required; for example only)
        CFNotificationCenterRef center = CFNotificationCenterGetLocalCenter();
        CFNotificationCenterAddObserver(center, NULL, WillEnterForeground, CFSTR("UIApplicationWillEnterForegroundNotification"), NULL, CFNotificationSuspensionBehaviorCoalesce);

        // listen for system-side notification (not required; for example only)
        // this would be posted using: notify_post("com.0x1306a94.hook-gps.eventname");
        CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(darwin, NULL, ExternallyPostedNotification, CFSTR("com.0x1306a94.hook-gps.eventname"), NULL, CFNotificationSuspensionBehaviorCoalesce);

        // CHLoadClass(CLLocation);  // load class (that is "available now")
        // CHLoadLateClass(ClassToHook);  // load class (that will be "available later")
        //        CHLoadClass(CLLocation);
        //        CHHook1(CLLocationManager, setDelegate);

        //        CHLoadClass(CLLocation);
        CHLoadClass(CLLocationManager);

        //        CHHook0(CLLocation, coordinate);
        CHHook1(CLLocationManager, setDelegate);


        //        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        //
        //            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FakeGPS" message:nil preferredStyle:UIAlertControllerStyleAlert];
        //
        //            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        //
        //            [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
        //        }];

    }
}
