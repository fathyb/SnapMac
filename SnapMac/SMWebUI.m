//
//  SMWebUI.m
//  SnapMac
//
//  Created by Fathy B on 01/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMWebUI.h"
#import "SMBlockItem.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "SnapJS.h"

SnapJS* snapJS;
@implementation SMWebUI


-(void)awakeFromNib {
    self.UIDelegate      = self;
    self.drawsBackground = NO;
    
    if(isYosemite()) {
        if([self respondsToSelector:@selector(setOpaque:)] && [self respondsToSelector:@selector(setBackgroundColor:)]) {
            [self performSelector:@selector(setOpaque:) withObject:@NO];
            [self performSelector:@selector(setBackgroundColor:) withObject:NSColor.clearColor];
        }
    }
    snapJS   = [SnapJS new];
    
    self.frameLoadDelegate = self;
    
    NSString *resourcesPath = NSBundle.mainBundle.resourcePath;
    NSString *htmlPath      = [resourcesPath stringByAppendingString:@"/mainUI.html"];
    [self.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
}

-(void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
    snapJS.webView   = self;
    [sender.windowScriptObject setValue:snapJS
                                 forKey:@"SnapJS"];
}

-(NSArray*)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    if(!element[@"WebElementDOMNode"])
        return defaultMenuItems;
    
    WebScriptObject *el     = element[@"WebElementDOMNode"];
    NSMutableArray *items   = NSMutableArray.new;
    
    WebScriptObject *result = [self.windowScriptObject callWebScriptMethod:@"SnappyRClickHandler"
                                                             withArguments:@[el]];
    
    if(![result isKindOfClass:WebUndefined.class]) {
        JSContextRef       jsContext = self.webFrame.globalContext;
        JSObjectRef         jsObject = result.JSObject;
        if(JSValueIsNull(self.webFrame.globalContext, jsObject))
            goto quit;
        
        JSPropertyNameArrayRef props = JSObjectCopyPropertyNames(jsContext, jsObject);
        ssize_t            arraySize = JSPropertyNameArrayGetCount(props);
        
        for(ssize_t i = 0; i < arraySize; i++) {
            JSStringRef    k = JSPropertyNameArrayGetNameAtIndex(props, i);
            JSValueRef  vval = JSObjectGetProperty(jsContext, jsObject, k, nil);
            NSString  *title = (NSString*)CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, k));
            NSMenuItem *item;
            
            JSStringRelease(k);
            
            if([title isEqualToString:@"separator"])
                item = NSMenuItem.separatorItem;
            else
                item = [SMBlockItem.alloc initWithTitle:title
                                                  block:^(NSMenuItem* item) {
                                                        JSObjectRef object = el.JSObject;
                                                        JSObjectCallAsFunction(jsContext,
                                                                  (JSObjectRef)vval,
                                                                               0,
                                                                               1,
                                                                  (JSValueRef*)&object,
                                                                               0);
                } keyEquivalent:@""];
            
            [items addObject:item];
        }
    }
    goto quit;
    
quit:
#ifdef SnapBug
    [items addObjectsFromArray:defaultMenuItems];
#endif
    
    return items;
}


-(void)script:(NSString*)commande {
    
    [self.windowScriptObject performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:commande waitUntilDone:NO];
}
@end
