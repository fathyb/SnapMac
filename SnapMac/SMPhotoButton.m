//
//  SMPhotoButton.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 14/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMPhotoButton.h"

@implementation SMPhotoButton

-(void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect
                                                         xRadius:75.f
                                                         yRadius:75.f];
    
    NSRect flashRect = NSMakeRect(10, 50, 25, 25);
    NSBezierPath *flashPath = [NSBezierPath bezierPathWithRoundedRect:flashRect
                                                              xRadius:flashRect.size.width
                                                              yRadius:flashRect.size.width];
    
    NSShadow *shadow = NSShadow.new;
    CGFloat grayscl = self.dark ? 0 : 255;
    
    shadow.shadowColor = [NSColor colorWithCalibratedRed:grayscl
                                                   green:grayscl
                                                    blue:grayscl
                                                   alpha:1];
    shadow.shadowBlurRadius = 10;
    shadow.shadowOffset = NSMakeSize(0, 0);
    
    [path addClip];
    [shadow set];
    [NSColor.controlColor set];
    
    NSRectFill(dirtyRect);
    
    [NSColor.whiteColor set];
    [flashPath fill];
    
    [super drawRect:dirtyRect];
}
-(void)changeAppearance:(NSAppearance*)appearance {
    
    self.dark = [appearance.name.lowercaseString containsString:@"dark"];
    CGFloat grayscl = self.dark ? 0 : 180;
    NSButtonCell *cell = self.cell;
    
    cell.backgroundColor = [NSColor colorWithCalibratedRed:grayscl
                                                     green:grayscl
                                                      blue:grayscl
                                                     alpha:0.5];
    
    self.image = [NSImage imageNamed:@(grayscl ? "CameraBtnDark" : "CameraBtnLight")];
    self.image.size = NSMakeSize(50, 50);
    
    [self setNeedsDisplay];
}

-(void)awakeFromNib {
    [super awakeFromNib];
    
    [NSNotificationCenter.defaultCenter addObserverForName:@"SnappyChangeAppearance"
                                                    object:nil
                                                     queue:NSOperationQueue.mainQueue
                                                usingBlock:^(NSNotification* notif) {
                                                    [self changeAppearance:notif.object];
                                                }];
    
}

-(void)show {
    self.animator.alphaValue = .7;
}
-(void)mouseDown:(NSEvent*)event {
    _down = YES;
}
-(void)mouseUp:(NSEvent*)event {
    _down = NO;
    
    if(!self.alphaValue)
        return;
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyTakePhoto"
                                                      object:nil];
}

@end
