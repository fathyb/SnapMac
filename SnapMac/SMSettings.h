//
//  SMSettings.h
//  SnapMac
//
//  Created by Fathy B on 07/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMAndroidSync.h"
#import "SnapJS.h"

@interface SMSettings : NSObject {
    NSPanel *settingsWindow;
    __weak NSTextField *authTokenField;
    __weak NSTextField *userField;
}


@property NSWindow* window;

-(SMSettings*)initForWindow:(NSWindow*)window;
+(SMSettings*)sharedInstance;
-(void)show;
-(void)setObject:(id)object forKey:(NSString*)key;
-(id)objectForKey:(NSString*)key;

@property (strong) IBOutlet NSPanel *settingsWindow;
@property (weak) IBOutlet NSPopUpButton *themeBtn;
@property (weak) IBOutlet NSTextField *themeTxt;
@property (weak) IBOutlet NSButton *checkbox3D;
@property (weak) IBOutlet NSButton *checkboxParallax;
@property (weak) IBOutlet NSButton *checkboxFeedPics;

@end
