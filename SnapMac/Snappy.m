//
//  SMAppDelegate.m
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "Snappy.h"
#import "SMConnection.h"
#import "SMAndroidSync.h"
#import <objc/runtime.h>

#include <errno.h>
#include <sys/sysctl.h>


@implementation Snappy
@synthesize effectList;

NSImage *current;
BOOL hideDivider = NO;

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    _effects = @{
        @"Chrome": @"CIPhotoEffectChrome",
        @"Fondu": @"CIPhotoEffectFade",
        @"Instantané": @"CIPhotoEffectInstant",
        @"Mono": @"CIPhotoEffectMono",
        @"Noir": @"CIPhotoEffectNoir",
        @"Processus": @"CIPhotoEffectProcess",
        @"Tonal": @"CIPhotoEffectTonal",
        @"Transfert": @"CIPhotoEffectTransfer"
    };
    _photoToolsYPos.constant = -110;
    
    self.window.title = @"Snappy - chargement";
    
    self.window.delegate = self;
    self.settingsView    = [Settings.alloc initForWindow:_window];
    
    self.about = About.new;
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center postNotificationName:@"IGotCamPosConstraint"
                          object:self.camPosConstraint];
    
    self.clearFeedWindow = SMClearFeedWindow.new;
    self.window.settingsWindow = self.settingsView.settingsWindow;
    self.window.webUI = self.webUI;
    self.window.aboutWindow = self.about.aboutWindow;
    self.about.window = self.window;
    
    if(isYosemite()) {
        NSAppearance *appearance = [NSAppearance appearanceNamed:[_settingsView objectForKey:@"SMDefaultTheme"]];
        self.window.appearance = appearance;
        self.window.movableByWindowBackground = NO;
    }
    [self setEffects];
    
    self.effectList.superview.layer = CALayer.new;
    self.window.title = @"Snappy (Beta 1)";
    NSUserNotificationCenter.defaultUserNotificationCenter.delegate = self;
}
-(void)showPhotoTools {
    _photoToolsYPos.animator.constant = 0;
}
-(void)hidePhotoTools {
    _photoToolsYPos.animator.constant = -110;
}
- (IBAction)photoToolsBtn:(id)sender {
    if(((NSButton*)sender).state)
        [self hidePhotoTools];
    else
        [self showPhotoTools];
    
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}
-(void)showSend {
    [self.webView script:@"SnappyUI.SendPage.show(true);"];
}
- (IBAction)cancelPhotoView:(id)sender {
    [self.camView cleanStart];
    [self.webView script:@"SnappyUI.SendPage.hide();"];
}

- (IBAction)showMySnaps:(id)sender {
}
- (IBAction)showFeed:(id)sender {
    [self.webView script:@"SnappyUI.FeedPage.show();"];
}
- (IBAction)showFriends:(id)sender {
    
    [self.webView script:@"SnappyUI.FriendsPage.show();"];
}
- (IBAction)showSettings:(id)sender {
    [_settingsView show];
}
- (IBAction)deconnection:(id)sender {
    [self.webView script:@"SnappyUI.logout();"];
}


-(IBAction)showAbout:(id)sender {
    [NSNotificationCenter.defaultCenter postNotificationName:@"ShowAboutWindow"
                                                      object:self];
}

- (IBAction)changePhotoEffect:(NSPopUpButton*)sender {
    
    NSString* effect = _effects[sender.selectedItem.title];
    CIFilter* filter = effect ? [CIFilter filterWithName:effect] : nil;
    
    [self.camView setFilter:filter];
}

-(void)nextFilter {
    NSInteger selectedItem = effectList.indexOfSelectedItem;
    if(selectedItem == _effects.count || selectedItem > _effects.count)
        [effectList selectItemAtIndex:0];
    else
        [effectList selectItemAtIndex:selectedItem+1];
    [self changePhotoEffect:effectList];
    
}
-(void)prevFilter {
    NSInteger selectedItem = effectList.indexOfSelectedItem;
    if(selectedItem == 0 || selectedItem < 0)
        [effectList selectItemAtIndex:effectList.itemArray.count-1];
    else
        [effectList selectItemAtIndex:selectedItem-1];
    [self changePhotoEffect:effectList];
    
}
-(void)setEffects {
    [effectList addItemWithTitle:@"Aucun effet"];
    for(NSString* effect in _effects)
        if([CIFilter filterWithName:_effects[effect]] != nil)
            [effectList addItemWithTitle:effect];
}

@end
