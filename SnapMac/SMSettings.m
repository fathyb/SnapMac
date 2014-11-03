//
//  SMSettings.m
//  SnapMac
//
//  Created by Fathy B on 07/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMSettings.h"

static SMSettings *sharedInstance;
static NSMutableArray *onloadBlocks;

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
        _snapJs = [SnapJS new];
        [self set3D];
        [self setTheme];
        
        sharedInstance = self;
        [self checkBlocks];
    }
    return self;
}
-(void)checkBlocks {
    for(SMCallback callback in [onloadBlocks copy]) {
        callback(self);
        [onloadBlocks removeObject:callback];
    }
}
+(void)addOnloadBlock:(SMCallback)onloadBlock {
    if(!onloadBlocks)
        onloadBlocks = [NSMutableArray new];
    [onloadBlocks addObject:onloadBlock];
    
    if(sharedInstance)
        [sharedInstance checkBlocks];
}
+(SMSettings*)sharedInstance {
    return sharedInstance;
}
-(void)set3D {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL use3D = [[self objectForKey:@"SMUse3D"] boolValue];
        [_snapJs setUse3D:use3D];
        [_checkbox3D setState:(use3D ? NSOnState : NSOffState)];
    });
}
-(IBAction)switch3D:(id)sender {
    [self setObject:@([sender state] == NSOnState) forKey:@"SMUse3D"];
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
            @"SMUseFlash": @YES
        }[key]);
        NSLog(@"Nouvelle object = %@", object);
        if(object)
            [self setObject:object forKey:key];
    }
    return object;
}
-(void)setObject:(id)object forKey:(NSString*)key {
    NSDictionary* actions = @{
        @"SMUse3D": ^{
            [_snapJs setUse3D:[object boolValue]];
        }
    };
    if(actions[key]) {
        void(^actionBlock)() = [actions objectForKey:key];
        actionBlock();
    }
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
}
-(void)show {
    NSLog(@"show ok");
    [NSApp beginSheet:settingsWindow modalForWindow:_window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}
-(void)setTheme {
    if(isYosemite()) {
        NSString *theme = [self objectForKey:@"SMDefaultTheme"];
        [(NSView*)settingsWindow.contentView setAppearance:[NSAppearance appearanceNamed:theme]];
        NSDictionary *themes = @{
            NSAppearanceNameVibrantLight: @0,
            NSAppearanceNameVibrantDark: @1
        };
        [_themeBtn selectItemAtIndex:[themes[theme] integerValue]];
    }
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
    NSAppearance *appearance = [NSAppearance appearanceNamed:theme];
    ((NSView*)_window.contentView).appearance = appearance;
    self.window.appearance = appearance;
    [self setTheme];
}
- (IBAction)close:(id)sender {
    [NSApp endSheet:settingsWindow];
    [settingsWindow orderOut:nil];
}
@end
