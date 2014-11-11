//
//  SMWebUI.m
//  SnapMac
//
//  Created by Fathy B on 01/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMWebUI.h"
#import "SMJSClient.h"

@implementation SMWebUI

-(void)setAllowsVibrancy:(BOOL)boolean {}

-(void)awakeFromNib {
    self.UIDelegate      = self;
    self.drawsBackground = NO;
    
    if(isYosemite()) {
        if([self respondsToSelector:@selector(setOpaque:)] && [self respondsToSelector:@selector(setBackgroundColor:)]) {
            [self performSelector:@selector(setOpaque:) withObject:@NO];
            [self performSelector:@selector(setBackgroundColor:) withObject:[NSColor clearColor]];
        }
        if([self respondsToSelector:@selector(setAllowsVibrancy:)]) {
            [self performSelector:@selector(setAllowsVibrancy:) withObject:@YES];
        }
    }
    
    NSString *resourcesPath = [NSBundle mainBundle].resourcePath;
    NSString *htmlPath      = [resourcesPath stringByAppendingString:@"/mainUI.html"];
    [self.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
    
    self.jsClient = [SMJSClient new];
    self.SnapJS   = [SnapJS new];
    
    self.jsClient.webView = self;
    self.SnapJS.wso       = self.windowScriptObject;
    
    [self.windowScriptObject setValue:self.jsClient forKey:@"SMClient"];
    [self.windowScriptObject setValue:self.SnapJS   forKey:@"SnapJS"];
    
    
    NSScrollView* scrollView = (NSScrollView *)(self.mainFrame.frameView.subviews[0]);
    scrollView.verticalScrollElasticity = NSScrollElasticityAllowed;
}
/*
-(id)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    NSLog(@"elements = %@", element);
    return;
    return @[
             [[NSMenuItem alloc] initWithTitle:@"test 1" action:nil keyEquivalent:@""],
             [[NSMenuItem alloc] initWithTitle:@"test 2" action:nil keyEquivalent:@""]
             ];
}*/


-(void)script:(NSString*)commande {
    [self.windowScriptObject performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:commande waitUntilDone:NO];
}
@end
