//
//  About.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 17/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "About.h"

@implementation About

-(instancetype)init {
    if(self = [super init]) {
        
        _window = [[NSApplication sharedApplication] mainWindow];
        
        [[NSBundle mainBundle] loadNibNamed:@"About"
                                      owner:self
                            topLevelObjects:nil];
        
        _aboutWindow.opaque = NO;
        _aboutWindow.backgroundColor = [NSColor clearColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showAbout)
                                                     name:@"ShowAboutWindow"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(closeAbout:)
                                                     name:@"CloseAboutWindow"
                                                   object:nil];
    }
    
    return self;
}

- (void)showAbout {
    [NSApp beginSheet:_aboutWindow
       modalForWindow:_window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

- (IBAction)closeAbout:(id)sender {
    [NSApp endSheet:_aboutWindow];
    [_aboutWindow orderOut:nil];
}

@end
