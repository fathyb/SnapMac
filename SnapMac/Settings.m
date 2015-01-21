//
//  Settings.m
//  SnapMac
//
//  Created by Fathy B on 07/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "Settings.h"

static Settings *sharedInstance;

@implementation Settings
@synthesize settingsWindow;

-(Settings*)initForWindow:(NSWindow*)window {
    if(self = [super init]) {
        _window = window;
        [[NSBundle mainBundle] loadNibNamed:@"Settings" owner:self topLevelObjects:nil];
        if(!isYosemite()) {
            [_themeBtn removeFromSuperview];
            [_themeTxt removeFromSuperview];
        }
        [self propageSettings];
        [self setTheme];
        
        sharedInstance = self;
        [NSNotificationCenter.defaultCenter postNotificationName:@"SnappySettingsLoaded" object:self];
    }
    return self;
}

+(Settings*)sharedInstance {
    return sharedInstance;
}
-(void)propageSettings {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        NSNumber* use3D = [self objectForKey:@"SMUse3D"];
        [center postNotificationName:@"SnappyUse3D" object:use3D];
        [_checkbox3D setState:(use3D.boolValue ? NSOnState : NSOffState)];
        
        NSNumber* useParallax = [self objectForKey:@"SMUseParallax"];
        [center postNotificationName:@"SnappyUseParallax" object:useParallax];
        [_checkboxParallax setState:(useParallax.boolValue ? NSOnState : NSOffState)];
        
        NSNumber* hideFeedPics = [self objectForKey:@"SMHideFeedPics"];
        [center postNotificationName:@"SnappyHideFeedPics" object:hideFeedPics];
        [_checkboxFeedPics setState:(hideFeedPics.boolValue ? NSOnState : NSOffState)];
        
    });
}
-(id)objectForKey:(NSString*)key {
    id object = [NSUserDefaults.standardUserDefaults objectForKey:key];

    if([object isKindOfClass:NSString.class]) {
        object = [object stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if(!((NSString*)object).length)
            object = nil;
    }
    if(!object) {
        object = (@{
            @"SMDefaultTheme": @"NSAppearanceNameVibrantLight",
            @"SMUse3D": @YES,
            @"SMUseFlash": @YES,
            @"SMUseParallax": @NO,
            @"SnappyHideFeedPics": @NO,
            @"SMMaxPDL": @5
        }[key]);
        if(object)
            [self setObject:object forKey:key];
    }
    return object;
}
-(void)setObject:(id)object forKey:(NSString*)key {
    NSDictionary* actions = @{
        @"SMUse3D": ^{
            [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyUse3D"
                                                                object:object];
        },
        @"SMUseParallax": ^{
            [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyUseParallax"
                                                                object:object];
        },
        @"SMHideFeedPics": ^{
            [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyHideFeedPics"
                                                                object:object];
        }
    };
    if(actions[key]) {
        void(^actionBlock)() = [actions objectForKey:key];
        actionBlock();
    }
    [NSUserDefaults.standardUserDefaults setObject:object forKey:key];
}
-(void)show {
    [NSApp beginSheet:settingsWindow modalForWindow:_window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}
-(void)setTheme {
    if(isYosemite()) {
        NSString *theme = [self objectForKey:@"SMDefaultTheme"];
        NSAppearance *appearance = [NSAppearance appearanceNamed:theme];
        _window.appearance = appearance;
        //settingsWindow.appearance = appearance;
        ((NSView*)settingsWindow.contentView).appearance = appearance;
        NSDictionary *themes = @{
            NSAppearanceNameVibrantLight: @0,
            NSAppearanceNameVibrantDark: @1
        };
        [_themeBtn selectItemAtIndex:[themes[theme] integerValue]];
    }
}
- (IBAction)switchParallax:(NSButton*)sender {
    [self setObject:@(sender.state == NSOnState) forKey:@"SMUseParallax"];
}
-(IBAction)switch3D:(NSButton*)sender {
    [self setObject:@(sender.state == NSOnState) forKey:@"SMUse3D"];
}
- (IBAction)switchFeedPics:(NSButton*)sender {
    [self setObject:@(sender.state == NSOnState) forKey:@"SMHideFeedPics"];
}
- (IBAction)changeTheme:(NSPopUpButton*)btn {
    if(!isYosemite())
        return;
    
    NSDictionary *themes = @{
        NSLoc(@"Light") : NSAppearanceNameVibrantLight,
        NSLoc(@"Dark") : NSAppearanceNameVibrantDark
    };
    NSString *theme = themes[btn.selectedItem.title];
    [self setObject:theme forKey:@"SMDefaultTheme"];
    [self setTheme];
}
- (IBAction)close:(id)sender {
    [NSApp endSheet:settingsWindow];
    [settingsWindow orderOut:nil];
}
@end
