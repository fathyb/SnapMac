//
//  SMSettings.m
//  SnapMac
//
//  Created by Fathy B on 07/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMSettings.h"

static SMSettings *sharedInstance;

@implementation SMSettings
@synthesize settingsWindow;

-(SMSettings*)initForWindow:(NSWindow*)window {
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SnappySettingsLoaded" object:self];
    }
    return self;
}

+(SMSettings*)sharedInstance {
    return sharedInstance;
}
-(void)propageSettings {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNumber* use3D = [self objectForKey:@"SMUse3D"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SnappyUse3D" object:use3D];
        [_checkbox3D setState:(use3D.boolValue ? NSOnState : NSOffState)];
        
        NSNumber* useParallax = [self objectForKey:@"SMUseParallax"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SnappyUseParallax" object:useParallax];
        [_checkboxParallax setState:(useParallax.boolValue ? NSOnState : NSOffState)];
        
    });
}
-(id)objectForKey:(NSString*)key {
    id object = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if([object isKindOfClass:[NSString class]]) {
        object = [object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(!((NSString*)object).length)
            object = nil;
    }
    if(!object) {
        object = (@{
            @"SMDefaultTheme": @"NSAppearanceNameVibrantLight",
            @"SMUse3D": @YES,
            @"SMUseFlash": @YES,
            @"SMUseParallax": @NO,
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SnappyUse3D"
                                                                object:object];
        },
        @"SMUseParallax": ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SnappyUseParallax"
                                                                object:object];
        }
    };
    if(actions[key]) {
        void(^actionBlock)() = [actions objectForKey:key];
        actionBlock();
    }
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
}
-(void)show {
    [NSApp beginSheet:settingsWindow modalForWindow:_window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}
-(void)setTheme {
    if(isYosemite()) {
        NSString *theme = [self objectForKey:@"SMDefaultTheme"];
        _window.appearance = [NSAppearance appearanceNamed:theme];
        NSDictionary *themes = @{
            NSAppearanceNameVibrantLight: @0,
            NSAppearanceNameVibrantDark: @1
        };
        [_themeBtn selectItemAtIndex:[themes[theme] integerValue]];
    }
}
- (IBAction)switchParallax:(id)sender {
    [self setObject:@([sender state] == NSOnState) forKey:@"SMUseParallax"];
}
-(IBAction)switch3D:(id)sender {
    [self setObject:@([sender state] == NSOnState) forKey:@"SMUse3D"];
}
- (IBAction)changeTheme:(id)sender {
    if(!isYosemite())
        return;
    NSPopUpButton *btn = (NSPopUpButton*)sender;
    NSDictionary *themes = @{
        @"Clair": NSAppearanceNameVibrantLight,
        @"Sombre": NSAppearanceNameVibrantDark
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
