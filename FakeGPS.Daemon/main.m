//
//  main.m
//  FakeGPS.Daemon
//
//  Created by king on 2019/8/28.
//  Copyright (c) 2019 ___ORGANIZATIONNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <spawn.h>

#import "CommonDefs.h"

extern char **environ;
void run_cmd(char *cmd);
void redirectConsoleLogToVarRoot(void);

int main(int argc, const char *argv[]) {

    redirectConsoleLogToVarRoot();
    NSFileManager *manager     = [NSFileManager defaultManager];
    NSError *error             = nil;
    NSString *dir              = @"/private/var/containers/Bundle/Application";
    NSArray<NSString *> *paths = [manager contentsOfDirectoryAtPath:dir error:&error];
    if (error) {
        NSLog(@"读取用户APP目录出错....: %@", error);
    } else if (paths.count > 0) {

        NSMutableDictionary<NSString *, NSString *> *apps = [NSMutableDictionary<NSString *, NSString *> dictionary];
        NSMutableString *logs                             = [NSMutableString string];
        [logs appendString:@"{\n"];
        [paths enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            @try {
                NSString *root         = [dir stringByAppendingPathComponent:obj];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.app'"];
                NSString *appNameDir   = [[[manager subpathsOfDirectoryAtPath:root error:nil] filteredArrayUsingPredicate:predicate] firstObject];
                if (appNameDir.length > 0) {
                    NSString *infoPlistPath = [[root stringByAppendingPathComponent:appNameDir] stringByAppendingPathComponent:@"Info.plist"];
                    if ([manager fileExistsAtPath:infoPlistPath]) {
                        NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:infoPlistPath];
                        NSString *key      = info[@"CFBundleIdentifier"] ?: @"";
                        NSString *value    = @"";
                        if (info[@"CFBundleName"]) {
                            value = [NSString stringWithFormat:@"%@.app", info[@"CFBundleName"]];
                            [logs appendFormat:@"\t\"%@\" = \"%@.app\";\n", key, info[@"CFBundleName"]];
                        } else {
                            value = appNameDir;
                            [logs appendFormat:@"\t\"%@\" = \"%@\";\n", key, appNameDir];
                        }
                        apps[key] = value;
                    }
                }
            } @catch (NSException *exception) {
                NSLog(@"发生异常: %@", exception);
                *stop = YES;
            } @finally {
            }
            if (apps.allValues.count > 0) {
                [logs appendString:@"}"];
                NSLog(@"APP: \n%@", logs);
                if ([apps writeToFile:kFakeGPSAPPSKey atomically:YES]) {
                    NSLog(@"写入成功...");
                }
            }
        }];
    }

    @autoreleasepool {
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

