//
//  SMQuitMedieButton.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 15/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMQuitMediaButton.h"

@implementation SMQuitMediaButton

-(void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect
                                                         xRadius:5.f
                                                         yRadius:5.f];
    [path addClip];
    
    [super drawRect:dirtyRect];
    
}

-(void)show {
    self.animator.alphaValue = 0.5;
}
@end
