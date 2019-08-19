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

#ifdef DEBUG
#define LOG(fmt, ...) NSLog((@"fake gps: " fmt), ##__VA_ARGS__);
#else
#define LOG(...) ;
#endif

#endif /* CommonDefs_h */
