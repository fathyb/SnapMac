//
//  main.m
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "main.h"
#import <objc/runtime.h>
#include <errno.h>
#include <sys/sysctl.h>


void debugOutput(char* filename, const char* function, int linenumber, NSString* input, ...) {
    va_list argList;
    
    NSString *filePath = [[NSString alloc] initWithBytes:filename
                                                  length:strlen(filename)
                                                encoding:NSUTF8StringEncoding];
    
    NSString *format = [NSString stringWithFormat:@"[%@ -> %s][ligne %d] : %@", [filePath lastPathComponent], function, linenumber, input];
    
    va_start(argList, input);
    
    NSString *directory = [NSString stringWithFormat:@"%@/SnapMac", NSHomeDirectory()];
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:directory isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@", directory);
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *defaultParams = @{
                                    @"SMDefaultTheme": @"",
                                    @"SMStoryAnimation": @"true"
                                    };
    for(NSString *key in defaultParams) {
        if(![defaults objectForKey:key])
            [defaults setObject:defaultParams[key] forKey:key];
    }
    NSLogv(format, argList);
    va_end(argList);
}

BOOL isYosemite() {
    char str[256];
    size_t size = sizeof(str);
    sysctlbyname("kern.osrelease", str, &size, NULL, 0);
    NSNumberFormatter * f = [NSNumberFormatter new];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber * kernelVersion = [f numberFromString:[[NSString stringWithFormat:@"%s", str] substringToIndex:2]];
    NSLog(@"Asking for kernel version.. response : Darwin %@", kernelVersion);
    if([kernelVersion isGreaterThan:@13]) return YES;
    return NO;
}
int main(int argc, const char * argv[]) {
    NSLog(@"SnapMac lancement....., l'aventure commence!!\n");
#if SnapBug
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"WebKitDeveloperExtras":@YES}];
#else
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"WebKitDeveloperExtras":@NO}];
#endif
    if(![NSVisualEffectView class])
        objc_allocateClassPair([NSView class], "NSVisualEffectView", 0);
    return NSApplicationMain(argc, argv);
}
