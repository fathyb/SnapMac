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
#import "SnappyFunction.h"

id JSToNS(JSValueRef object);

@implementation SMWebUI


-(void)awakeFromNib {
    self.drawsBackground   = NO;
    self.UIDelegate        = self;
    self.frameLoadDelegate = self;
    self.snapJS            = SnapJS.new;
    
    if(isYosemite()) {
        if([self respondsToSelector:@selector(setOpaque:)] && [self respondsToSelector:@selector(setBackgroundColor:)]) {
            [self performSelector:@selector(setOpaque:) withObject:@NO];
            [self performSelector:@selector(setBackgroundColor:) withObject:NSColor.clearColor];
        }
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(changeAppearance:)
                                               name:@"SnappyChangeAppearance"
                                             object:nil];
    
    NSString *resourcesPath = NSBundle.mainBundle.resourcePath;
    NSString *htmlPath      = [resourcesPath stringByAppendingString:@"/mainUI.html"];
    [self.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
}

-(void)changeAppearance:(NSNotification*)notif {
    self.appearance = notif.object;
}

-(void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
    self.snapJS.webView = self;
    [sender.windowScriptObject setValue:self.snapJS
                                 forKey:@"SnapJS"];
}
- (BOOL)validateMenuItem:(NSMenuItem *)item {
    return item.isEnabled;
}
-(NSArray*)        webView:(WebView *)sender
contextMenuItemsForElement:(NSDictionary *)element
          defaultMenuItems:(NSArray *)defaultMenuItems {
    
    
    WebScriptObject *el = element[@"WebElementDOMNode"];
    
    if(!el) {
#ifdef Snapbug
        return defaultMenuItems;
#else
        return @[];
#endif
    }
    
    if([el isKindOfClass:DOMText.class])
        el = ((DOMText*)el).parentNode;
    
    NSMutableArray *items   = NSMutableArray.new;
    WebScriptObject *result = [self.windowScriptObject callWebScriptMethod:@"SnappyRClickHandler"
                                                             withArguments:@[el]];
    
    if(result.class != WebUndefined.class) {
        NSDictionary *resultDict = result.toObjCObject;
        for(NSString *title in resultDict.allKeys) {
            id        object = [resultDict objectForKey:title];
            NSMenuItem *item = nil;
            
            if([title isEqualToString:@"separator"])
                item = NSMenuItem.separatorItem;
            else
                item = [SMBlockItem.alloc initWithTitle:title
                                                  block:^(NSMenuItem* item) {
                                                       if([object isKindOfClass:SnappyFunction.class])
                                                           [object call:el, nil];
                                        } keyEquivalent:@""];
            
            if([object isKindOfClass:NSString.class]) {
                item.enabled = NO;
            }
            [items addObject:item];
        }
    }
    
#ifdef SnapBug
    [items addObject:NSMenuItem.separatorItem];
    [items addObjectsFromArray:defaultMenuItems];
#endif
    
    return items;
}


-(void)script:(NSString*)commande {
    
    [self.windowScriptObject performSelectorOnMainThread:@selector(evaluateWebScript:)
                                              withObject:commande
                                           waitUntilDone:NO];
}
@end
