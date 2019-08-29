//
//  main.m
//  FakeGPS.Daemon
//
//  Created by king on 2019/8/28.
//  Copyright (c) 2019 ___ORGANIZATIONNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <notify.h>
#import <spawn.h>

#import "CommonDefs.h"

extern char **environ;
void run_cmd(char *cmd);
void redirectConsoleLogToVarRoot(void);
void regLinstenersOnMsgPass(void);

int main(int argc, const char *argv[]) {

    @autoreleasepool {
        redirectConsoleLogToVarRoot();

        regLinstenersOnMsgPass();
        NSLog(@"[*] Daemon 初始化完成");

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSFileManager *manager     = [NSFileManager defaultManager];
            NSError *error             = nil;
            NSString *dir              = @"/private/var/containers/Bundle/Application";
            NSArray<NSString *> *paths = [manager contentsOfDirectoryAtPath:dir error:&error];
            if (error) {
                NSLog(@"读取用户APP目录出错....: %@", error);
            } else if (paths.count > 0) {

                NSMutableArray<NSDictionary<NSString *, id> *> *apps = [NSMutableArray<NSDictionary<NSString *, id> *> array];
                [paths enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    @try {
                        NSString *root         = [dir stringByAppendingPathComponent:obj];
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.app'"];
                        NSString *appNameDir   = [[[manager subpathsOfDirectoryAtPath:root error:nil] filteredArrayUsingPredicate:predicate] firstObject];
                        if (appNameDir.length > 0) {
                            NSString *infoPlistPath = [[root stringByAppendingPathComponent:appNameDir] stringByAppendingPathComponent:@"Info.plist"];
                            if ([manager fileExistsAtPath:infoPlistPath]) {
                                NSMutableDictionary<NSString *, id> *tmp = [NSMutableDictionary<NSString *, id> dictionary];

                                NSDictionary *info           = [[NSDictionary alloc] initWithContentsOfFile:infoPlistPath];
                                NSString *bundleIdentifier   = info[@"CFBundleIdentifier"] ?: @"";
                                NSString *appName            = info[@"CFBundleDisplayName"] ?: [appNameDir stringByReplacingOccurrencesOfString:@".app" withString:@""];
                                tmp[kAppBundleIdentifierKey] = bundleIdentifier;
                                tmp[kAppNameKey]             = appName;

                                // 获取APP Icon
                                NSMutableArray<NSString *> *iconPtahs = [NSMutableArray<NSString *> array];
                                NSArray<NSString *> *infoIcons        = [info valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"];
                                [infoIcons enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                    if ([obj hasSuffix:@"60"]) {
                                        [iconPtahs addObject:[[root stringByAppendingPathComponent:appNameDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.png", obj]]];
                                        [iconPtahs addObject:[[root stringByAppendingPathComponent:appNameDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@3x.png", obj]]];
                                        *stop = YES;
                                    }
                                }];
                                [iconPtahs enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                    if ([manager fileExistsAtPath:obj]) {
                                        UIImage *image = [UIImage imageWithContentsOfFile:obj];
                                        if (image) {
                                            NSLog(@"读取APP Icon 成功: %@ %@", appName, image);
                                            tmp[kAppIconKey] = image;
                                            *stop            = YES;
                                        }
                                    }
                                }];
                                [apps addObject:tmp];
                            }
                        }
                    } @catch (NSException *exception) {
                        NSLog(@"发生异常: %@", exception);
                        *stop = YES;
                    } @finally {
                    }

                    if (apps.count > 0) {
                        if ([NSKeyedArchiver archiveRootObject:apps toFile:kFakeGPSAPPSKey]) {
                            NSLog(@"写入成功...");
                        }
                    }
                }];
            }
        });
        CFRunLoopRun();
    }
    return 0;
}

void run_cmd(char *cmd) {
    pid_t pid;
    char *argv[] = {"sh", "-c", cmd, NULL, NULL};
    int status;

    NSString *cmdStr = [[NSString alloc] initWithUTF8String:cmd];
    NSLog(@"[Execute] sh -c %@", cmdStr);

    status = posix_spawn(&pid, "/bin/sh", NULL, NULL, argv, environ);
    if (status == 0) {
        if (waitpid(pid, &status, 0) == -1) {
            perror("waitpid");
        }
    }
}

void redirectConsoleLogToVarRoot(void) {
    NSString *dirPath = @"/var/root/FakeGPS.Daemon/";
    NSString *mkdir   = [NSString stringWithFormat:@"mkdir -p %@", dirPath];
    run_cmd((char *)[mkdir UTF8String]);
    NSString *logPath = @"/var/root/FakeGPS.Daemon/out.log";
    if ([[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        run_cmd((char *)[[NSString stringWithFormat:@"rm -f %@", logPath] UTF8String]);
    }
    freopen([logPath fileSystemRepresentation], "a+", stderr);
    NSLog(@"[*] 重定向输出到文件： %@", logPath);
}

static void reload_cydia_conf() {
    NSLog(@"收到 com.0x1306a94.fake.gps.reload.cydia.conf 通知");
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:kInjectionTempPlistPath]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kInjectionTempPlistPath];
        if ([dict writeToFile:kInjectionPlistPath atomically:YES]) {
            NSLog(@"更新Cydia配置文件成功...");
        } else {
            NSLog(@"更新Cydia配置文件出错:");
        }
//        NSError *error = nil;
//        if ([manager copyItemAtPath:kInjectionTempPlistPath toPath:kInjectionPlistPath error:&error] && error == nil) {
//            NSLog(@"拷贝Cydia配置文件成功...");
//        } else if (error) {
//            NSLog(@"拷贝Cydia配置文件出错:\n%@", error);
//        }

    } else {
        NSLog(@"%@ 文件不存在", kInjectionTempPlistPath);
    }
}

void regLinstenersOnMsgPass() {

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    reload_cydia_conf,
                                    CFSTR("com.0x1306a94.fake.gps.reload.cydia.conf"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
}

