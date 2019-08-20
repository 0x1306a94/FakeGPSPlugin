//
//  KKGPSPlugin.mm
//  KKGPSPlugin
//
//  Created by king on 2019/8/20.
//  Copyright (c) 2019 ___ORGANIZATIONNAME___. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import "CaptainHook/CaptainHook.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#include <notify.h>  // not required; for examples only

#import "Aspects.h"

#import "CommonDefs.h"

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()

CHDeclareClass(CLLocationManager);
//CHDeclareClass(AMapLocationCLMDelegate);

CHOptimizedMethod1(self, void, CLLocationManager, setDelegate, id<CLLocationManagerDelegate>, delegate) {
	LOG(@"CLLocationManager delegate -> %@", delegate);
	CHSuper1(CLLocationManager, setDelegate, delegate);
	if (delegate) {
		/* clang-format off */
        [(NSObject *)delegate aspect_hookSelector:@selector(locationManager:didUpdateLocations:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
            LOG(@"locationManager:didUpdateLocations: arguments -> %@", aspectInfo.arguments);
            if ([[NSFileManager defaultManager] fileExistsAtPath:kFakeGPSFilePath]) {
                NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:kFakeGPSFilePath];
                LOG(@"%@", info);
                if (![info[kFakeStopKey] boolValue]) {
                    CLLocationDegrees latitude = [info[kFakeLatitudeKey] doubleValue];
                    CLLocationDegrees longitude = [info[kFakeLongitudeKey] doubleValue];
                    if (CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(latitude, longitude))) {
                        NSArray<CLLocation *> *fakeLocations = @[[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
                        [aspectInfo.originalInvocation setArgument:&fakeLocations atIndex:3];
                    }
                }
            }

        } error:nil];
		/* clang-format on */
	}
}

//CHOptimizedMethod2(self, void, AMapLocationCLMDelegate, locationManager, id, arg1, didUpdateLocations, id, arg2) {
//    if ([[NSFileManager defaultManager] fileExistsAtPath:kFakeGPSFilePath]) {
//        NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:kFakeGPSFilePath];
//        LOG(@"%@", info);
//        if (![info[kFakeStopKey] boolValue]) {
//            CLLocationDegrees latitude  = [info[kFakeLatitudeKey] doubleValue];
//            CLLocationDegrees longitude = [info[kFakeLongitudeKey] doubleValue];
//            if (CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(latitude, longitude))) {
//                arg2 = @[[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
//            }
//        }
//    }
//
//    CHSuper2(AMapLocationCLMDelegate, locationManager, arg1, didUpdateLocations, arg2);
//}

static void WillEnterForeground(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// not required; for example only
	LOG(@"%s", __FUNCTION__);
}

static void ExternallyPostedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// not required; for example only
}

CHConstructor {
	@autoreleasepool {
		// listen for local notification (not required; for example only)
		CFNotificationCenterRef center = CFNotificationCenterGetLocalCenter();
		CFNotificationCenterAddObserver(center, NULL, WillEnterForeground, CFSTR("UIApplicationWillEnterForegroundNotification"), NULL, CFNotificationSuspensionBehaviorCoalesce);

		// listen for system-side notification (not required; for example only)
		// this would be posted using: notify_post("com.0x1306a94.hook-gps.eventname");
		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, NULL, ExternallyPostedNotification, CFSTR("com.0x1306a94.hook-gps.eventname"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		LOG(@"FakeGPS-Plugin load");
		// CHLoadClass(CLLocation);  // load class (that is "available now")
		// CHLoadLateClass(ClassToHook);  // load class (that will be "available later")

		//        static CHClassDeclaration_ AMapLocationCLMDelegate$
		//        Class value = NSClassFromString(@"AMapLocationCLMDelegate");
		//        AMapLocationCLMDelegate$.class_ = value;
		//        AMapLocationCLMDelegate$.metaClass_ = object_getClass(value);
		//        AMapLocationCLMDelegate$.superClass_ = class_getSuperclass(value);

		CHLoadClass(CLLocationManager);

		CHHook1(CLLocationManager, setDelegate);
		//        CHHook2(AMapLocationCLMDelegate, locationManager, didUpdateLocations);
	}
}
