//
//  SMPhotoButton.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 14/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMPhotoButton.h"

@implementation SMPhotoButton


- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:75.f yRadius:75.f];
    [path addClip];
    
    [super drawRect:dirtyRect];
}


-(void)mouseDown:(NSEvent*)event {
    _down = YES;

}
-(void)mouseUp:(NSEvent*)event {
    _down = NO;
    if(_actionBlock && self.alphaValue != 0)
        _actionBlock();
}

@end
