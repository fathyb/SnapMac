//
//  SMFlashButton.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 19/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMFlashButton.h"
#import "Settings.h"

@implementation SMFlashButton


-(void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect
                                                         xRadius:35.f
                                                         yRadius:35.f];
    
    
    [path addClip];
    [NSColor.controlColor set];
    
    NSRectFill(dirtyRect);
    
    [super drawRect:dirtyRect];
}

-(void)awakeFromNib {
    [super awakeFromNib];
    
    [NSNotificationCenter.defaultCenter addObserverForName:@"SnappySettingsLoaded"
                                                    object:nil
                                                     queue:NSOperationQueue.mainQueue
                                                usingBlock:^(NSNotification* note) {
                                                    self.settings = note.object;
                                                    self.flashState = [[self.settings objectForKey:@"SMUseFlash"] boolValue];
    }];
}

-(void)mouseDown:(NSEvent *)theEvent {
    self.flashState = !self.flashState;
}
-(void)setFlashState:(SMFlashState)flashState {
    _flashState = flashState;
    self.animator.image  = [NSImage imageNamed:@(self.flashState ? "FlashIconAlternate" : "FlashIcon")];
    self.image.size = NSMakeSize(25, 25);
    [self.settings setObject:@(self.flashState) forKey:@"SMUseFlash"];
}
@end
