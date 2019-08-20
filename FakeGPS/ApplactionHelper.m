//
//  ApplactionHelper.m
//  FakeGPS
//
//  Created by king on 2019/8/19.
//

#import "Applaction.h"
#import "ApplactionHelper.h"

#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <dlfcn.h>

#import "AppList.h"

@implementation ApplactionHelper
+ (void)scanApps {

    char *path = "/Library/MobileSubstrate/DynamicLibraries/AppList.dylib";
    void *lib  = dlopen(path, RTLD_LAZY);
    if (lib == NULL) {
        return;
    }

	NSObject *sharedApplicationList = [NSClassFromString(@"ALApplicationList") performSelector:@selector(sharedApplicationList)];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isSystemApplication = TRUE"];
	BOOL onlyVisible       = YES;
	NSArray *sortedDisplayIdentifiers;

	SEL sel                            = @selector(applicationsFilteredUsingPredicate:onlyVisible:titleSortedIdentifiers:);
	NSMethodSignature *methodSignature = [sharedApplicationList methodSignatureForSelector:sel];
	NSInvocation *invoke               = [NSInvocation invocationWithMethodSignature:methodSignature];
	[invoke setSelector:sel];
	[invoke setTarget:sharedApplicationList];

	[invoke setArgument:&predicate atIndex:2];
	[invoke setArgument:&onlyVisible atIndex:3];
	[invoke setArgument:&sortedDisplayIdentifiers atIndex:4];
	[invoke invoke];

	void *returnValue;
	[invoke getReturnValue:&returnValue];
	NSDictionary *applications = (__bridge NSDictionary *)returnValue;

	NSString *pathOfApplications;
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
		pathOfApplications = @"/var/containers/Bundle/Application";
	} else {
		pathOfApplications = @"/var/mobile/Applications";
	}
	NSLog(@"scan begin");

	DIR *ptr_dir = opendir(pathOfApplications.UTF8String);

	NSFileManager *fileManager = [NSFileManager defaultManager];
	// all applications
	NSArray *arrayOfApplications = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:pathOfApplications error:nil];

	for (NSString *applicationDir in arrayOfApplications) {
		// path of an application
		NSString *pathOfApplication    = [pathOfApplications stringByAppendingPathComponent:applicationDir];
		NSArray *arrayOfSubApplication = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathOfApplication error:nil];
		// seek for *.app
		for (NSString *applicationSubDir in arrayOfSubApplication) {
			if ([applicationSubDir hasSuffix:@".app"]) {  // *.app
				NSString *path      = [pathOfApplication stringByAppendingPathComponent:applicationSubDir];
				NSString *imagePath = [pathOfApplication stringByAppendingPathComponent:applicationSubDir];
				path                = [path stringByAppendingPathComponent:@"Info.plist"];
				// so you get the Info.plist in the dict
				NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
				if ([[dict allKeys] containsObject:@"CFBundleIdentifier"] && [[dict allKeys] containsObject:@"CFBundleDisplayName"]) {
					NSArray *values = [dict allValues];
					NSString *icon;
					for (id obj in values) {
						icon = [self getIcon:obj withPath:imagePath];
						if (icon.length > 0) {
							imagePath = [imagePath stringByAppendingPathComponent:icon];
						}
					}
				}
			}
		}
	}
}

+ (NSString *)getIcon:(id)value withPath:(NSString *)imagePath {
	if ([value isKindOfClass:[NSString class]]) {
		NSRange range     = [value rangeOfString:@"png"];
		NSRange iconRange = [value rangeOfString:@"icon"];
		NSRange IconRange = [value rangeOfString:@"Icon"];
		if (range.length > 0) {
			NSString *path = [imagePath stringByAppendingPathComponent:value];
			UIImage *image = [UIImage imageWithContentsOfFile:path];
			if (image != nil && image.size.width > 50 && image.size.height > 50) {
				return value;
			}
		} else if (iconRange.length > 0) {
			NSString *imgUrl = [NSString stringWithFormat:@"%@.png", value];
			NSString *path   = [imagePath stringByAppendingPathComponent:imgUrl];
			UIImage *image   = [UIImage imageWithContentsOfFile:path];
			if (image != nil && image.size.width > 50 && image.size.height > 50) {
				return imgUrl;
			}
		} else if (IconRange.length > 0) {
			NSString *imgUrl = [NSString stringWithFormat:@"%@.png", value];
			NSString *path   = [imagePath stringByAppendingPathComponent:imgUrl];
			UIImage *image   = [UIImage imageWithContentsOfFile:path];
			if (image != nil && image.size.width > 50 && image.size.height > 50) {
				return imgUrl;
			}
		}
	} else if ([value isKindOfClass:[NSDictionary class]]) {
		NSDictionary *dict = (NSDictionary *)value;
		for (id subValue in [dict allValues]) {
			NSString *str = [self getIcon:subValue withPath:imagePath];
			if (![str isEqualToString:@""]) {
				return str;
			}
		}
	} else if ([value isKindOfClass:[NSArray class]]) {
		for (id subValue in value) {
			NSString *str = [self getIcon:subValue withPath:imagePath];
			if (![str isEqualToString:@""]) {
				return str;
			}
		}
	}
	return @"";
}
@end
