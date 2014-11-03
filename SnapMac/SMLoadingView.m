//
//  SMLoadingView.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 15/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMLoadingView.h"

@implementation SMLoadingView

-(void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:5.0 yRadius:5.0];
    [path addClip];
   
    [[NSColor colorWithCalibratedRed:0
                               green:0
                                blue:0
                               alpha:0.5] set];
    NSRectFill(dirtyRect);
}

@end
