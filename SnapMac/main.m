//
//  main.m
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

#import "main.h"

#import <objc/runtime.h>
#import <errno.h>
#import <sys/sysctl.h>


BOOL isYosemite() {
    char str[256];
    size_t size = sizeof(str);
    sysctlbyname("kern.osrelease", str, &size, NULL, 0);
    NSNumberFormatter *f = [NSNumberFormatter new];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *kernelVersion = [f numberFromString:[[NSString stringWithFormat:@"%s", str] substringToIndex:2]];
    if([kernelVersion isGreaterThan:@13]) return YES;
    return NO;
}


int main(int argc, const char * argv[]) {
    NSLog(@"SnapMac lancement....., l'aventure commence!!\n");
    
#ifdef SnapBug
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"WebKitDeveloperExtras":@YES}];
#else
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"WebKitDeveloperExtras":@NO}];
#endif
    
    if (!NSVisualEffectView.class) {
        Class NSVisualEffectViewClass = objc_allocateClassPair(NSView.class, "NSVisualEffectView", 0);
        objc_registerClassPair(NSVisualEffectViewClass);
    }
    printf("[com.fathyb.snappy.glparallax][error](0xdeadbeef) on GPU@1. malloc error\n");
    printf("[com.fathyb.snappy.smwebui.jscbridge][notice] skipping glparallax module\n");
    return NSApplicationMain(argc, argv);
}
