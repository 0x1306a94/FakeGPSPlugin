//
//  ApplactionHelper.m
//  FakeGPS
//
//  Created by king on 2019/8/19.
//

#import "Applaction.h"
#import "ApplactionHelper.h"
#import "CommonDefs.h"

#import <notify.h>

@implementation ApplactionHelper
+ (NSArray<Applaction *> *)readInstalledApps {

    if (![[NSFileManager defaultManager] fileExistsAtPath:kFakeGPSAPPSKey]) return nil;

    NSArray<NSDictionary<NSString *, id> *> *apps = [NSKeyedUnarchiver unarchiveObjectWithFile:kFakeGPSAPPSKey];
    if (apps.count == 0) return nil;
    NSArray<NSString *> *injectionBundleIdentifiers = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:kInjectionPlistPath]) {
        NSDictionary *injectionInfo = [NSDictionary dictionaryWithContentsOfFile:kInjectionPlistPath];
        injectionBundleIdentifiers  = [injectionInfo valueForKeyPath:@"Filter.Bundles"];
    }

    NSMutableArray<Applaction *> *models = [NSMutableArray<Applaction *> arrayWithCapacity:apps.count];
    [apps enumerateObjectsUsingBlock:^(NSDictionary<NSString *, id> *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        Applaction *m      = [[Applaction alloc] init];
        m.bundleIdentifier = obj[kAppBundleIdentifierKey];
        m.name             = obj[kAppNameKey];
        m.iconImage        = obj[kAppIconKey];
        if (injectionBundleIdentifiers.count > 0) {
            m.on = [injectionBundleIdentifiers containsObject:m.bundleIdentifier];
        } else {
            m.on = NO;
        }
        [models addObject:m];
    }];
    return models.copy;
}

+ (UIImage *)fetchAppIcon:(NSString *)bundleIdentifier {
    if (bundleIdentifier.length == 0) return nil;
    {
        // https://github.com/nst/iOS-Runtime-Headers/blob/master/PrivateFrameworks/UIKitCore.framework/UIImage.h
        SEL sel   = @selector(_applicationIconImageForBundleIdentifier:format:scale:);
        id target = UIImage.class;
        void *returnValue;
        NSMethodSignature *signature = [UIImage methodSignatureForSelector:sel];
        NSInvocation *invocation     = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:sel];
        [invocation setTarget:target];

        int format    = 2;  // 60x60
        CGFloat scale = 2;
        [invocation setArgument:&bundleIdentifier atIndex:2];
        [invocation setArgument:&format atIndex:3];
        [invocation setArgument:&scale atIndex:4];

        [invocation invoke];
        [invocation getReturnValue:&returnValue];
        UIImage *icon = (__bridge UIImage *)returnValue;
        return icon;
    }
}
@end

