//
//  SMAppDelegate.m
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "Snappy.h"
#import "SMConnection.h"
#import "ASIFormDataRequest.h"
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
    [self fixExtensions];
    self.window.title    = @"Snappy - chargement";
    
    
    self.window.delegate = self;
    self.settingsView    = [[SMSettings alloc] initForWindow:_window];
    self.about = [About new];
    
    self.window.settingsWindow = self.settingsView.settingsWindow;
    self.window.webUI = self.webUI;
    self.window.aboutWindow = self.about.aboutWindow;
    self.about.window = self.window;
    
    if(isYosemite()) {
        NSAppearance *appearance = [NSAppearance appearanceNamed:[_settingsView objectForKey:@"SMDefaultTheme"]];
        self.window.appearance = appearance;
        self.window.movableByWindowBackground = YES;
    }
    [self setEffects];
    self.photoButton.actionBlock = ^{
        [self.camView photo:^(NSImage* image) {
            [self.camView showImage:image];
            [self showSend];
        }];
    };
    self.effectList.superview.layer = [CALayer new];
    self.window.title = @"Snappy (Beta 1)";
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
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
-(void)fixExtensions {
    /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        NSFileManager *fManager = [NSFileManager defaultManager];
        NSArray *snaps = [fManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/SnapMac/", NSHomeDirectory()] error:nil];
        for(NSString* snap in snaps) {
            if([snap hasPrefix:@"."])
                return;

            NSString *filepath = [NSString stringWithFormat:@"%@/SnapMac/%@", NSHomeDirectory(), snap];
            NSDictionary *filetype = [SMClient fileTypeForFile:filepath];
            if(![filetype[@"extension"] isEqualToString:snap.pathExtension]) {
                NSString *newPath = [[filepath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",snap.stringByDeletingPathExtension, filetype[@"extension"]]];
                NSLog(@"moving path %@ to %@", filepath, newPath);
                [[NSFileManager defaultManager] moveItemAtPath:filepath toPath:newPath error:nil];
            }
        }
    });*/
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}
-(void)showSend {
    [self.webView script:@"SnappyUI.SendPage.show();"];
}
- (IBAction)cancelPhotoView:(id)sender {
    [self.camView cleanStart];
    [self.webView script:@"SnappyUI.hideSend();"];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowAboutWindow"
                                                        object:self];
}


-(void)updateTimer:(NSNumber*)percent {
    _progressLayer.bounds = NSMakeRect(0, 0, _camView.bounds.size.width*([percent floatValue]/100)*2, 10);
}
-(CGFloat)percentPlayedOfPlayer:(AVPlayer*)player andAsset:(AVURLAsset*)asset {
    if(player.currentTime.timescale) {
        CGFloat currentTime = player.currentTime.value/player.currentTime.timescale;
        CGFloat totalTime = asset.duration.value/asset.duration.timescale;
        return currentTime/totalTime*100;
    }
    return 0;
}
-(void)showVideo:(NSString*)videoUrl {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_session stopRunning];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoUrl] options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
        layer.backgroundColor = [NSColor blackColor].CGColor;
        CALayer *rootLayer = [CALayer new];
        [layer setFrame:_camView.frame];
        [rootLayer addSublayer:layer];
        
        _progressLayer = [CALayer new];
        _progressLayer.backgroundColor = [NSColor blueColor].CGColor;
        
        [rootLayer insertSublayer:_progressLayer above:layer];
        [_camView setLayer:rootLayer];
        [player seekToTime:kCMTimeZero];
        [player play];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while([player rate] != 0.0) {
                //[self performSelectorOnMainThread:@selector(updateTimer:) withObject:@([self percentPlayedOfPlayer:player andAsset:asset]) waitUntilDone:YES];
                [self updateTimer:@([self percentPlayedOfPlayer:player andAsset:asset])];
                usleep(1000);
            }
        });
    });
}
-(void)showImage:(NSString*)imageUrl {
    NSImage *sourceImage = [[NSImage alloc] initWithContentsOfFile:imageUrl];
    [self showNSImage:sourceImage];
}
-(void)showNSImage:(NSImage*)sourceImage {
    
    current = sourceImage;
    CGSize targetSize = _camView.bounds.size;
    
    if(targetSize.width == 0 || targetSize.height == 0) return;
    if(!sourceImage || ![sourceImage isValid]) return;
    NSImage *newImage = nil;
   
    NSSize imageSize = [sourceImage size];
    float width  = imageSize.width;
    float height = imageSize.height;
    
    float targetWidth  = targetSize.width;
    float targetHeight = targetSize.height;
    
    float scaleFactor  = 0.0;
    float scaledWidth  = targetWidth;
    float scaledHeight = targetHeight;
    
    NSPoint thumbnailPoint = NSZeroPoint;
    
    if(NSEqualSizes(imageSize, targetSize) == NO ) {
        float widthFactor  = targetWidth / width;
        float heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width  * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if (widthFactor < heightFactor)
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        
        else if (widthFactor > heightFactor)
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
    }
    
    newImage = [[NSImage alloc] initWithSize:targetSize];
    
    [newImage lockFocus];
    
    NSRect thumbnailRect;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect: thumbnailRect
                   fromRect: NSZeroRect
                  operation: NSCompositeSourceOver
                   fraction: 1.0];
    
    [newImage unlockFocus];
    
    if([_session isRunning]) {
        [_session stopRunning];
        [_previewLayer removeFromSuperlayer];
    }
    
    CALayer *layer = [CALayer new];
    layer.contents = newImage;
    [_camView setLayer:layer];
}
- (IBAction)changePhotoEffect:(NSPopUpButton*)sender {
    
    NSString* effet = _effects[[sender selectedItem].title];
    CIFilter* filter;
    if(!effet)
        filter = nil;
    else
        filter = [CIFilter filterWithName:effet];
    //[self.camView performSelectorOnMainThread:@selector(setFilter:) withObject:filter waitUntilDone:YES];
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
    for(NSString* effect in _effects) {
        if([CIFilter filterWithName:_effects[effect]] != nil) [effectList addItemWithTitle:effect];
    }
}

@end
