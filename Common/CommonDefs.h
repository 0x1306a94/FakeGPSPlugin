//
//  CommonDefs.h
//  FakeGPSPlugin
//
//  Created by king on 2019/8/19.
//

#ifndef CommonDefs_h
#define CommonDefs_h
#import <Foundation/Foundation.h>

static NSString *const kFakeGPSFilePath  = @"/var/mobile/Library/Preferences/com.0x1306a94.fake.gps.location.plist";
static NSString *const kFakeStopKey      = @"stop";
static NSString *const kFakeLatitudeKey  = @"latitude";
static NSString *const kFakeLongitudeKey = @"longitude";

static NSString *const kFakeGPSAPPSKey = @"/var/mobile/Library/Preferences/com.0x1306a94.fake.gps.apps.plist";

static NSString *const kInjectionPlistPath = @"/Library/MobileSubstrate/DynamicLibraries/KKGPSPlugin.plist";
static NSString *const kInjectionTempPlistPath = @"/var/mobile/Library/Preferences/com.0x1306a94.fake.gps.cydia.plist";

static NSString *const kAppBundleIdentifierKey = @"bundleIdentifier";
static NSString *const kAppNameKey             = @"name";
static NSString *const kAppIconKey             = @"icon";

static CFStringRef const kReadAppIconNotificationName = CFSTR("com.0x1306a94.read.appicon");
static CFStringRef const kSendAppIconNotificationName = CFSTR("com.0x1306a94.send.appicon");

static const char *kReloadDynamicLibrariesConfiguration = "com.0x1306a94.fake.gps.reload.cydia.conf";

#ifdef DEBUG
#define LOG(fmt, ...) NSLog((@"fake gps: " fmt), ##__VA_ARGS__);
#else
#define LOG(...) ;
#endif

#endif /* CommonDefs_h */

