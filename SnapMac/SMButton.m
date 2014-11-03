//
//  SMButton.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 16/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMButton.h"

@implementation SMButton

-(void)awakeFromNib {
    [super awakeFromNib];
    
    self.alphaValue = .5;
    
    ((NSButtonCell*)self.cell).backgroundColor = [NSColor colorWithCalibratedRed:255
                                                                           green:255
                                                                            blue:255
                                                                           alpha:0.5];
    
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}
-(void)show {
    self.animator.alphaValue = .5;
}
-(void)hide {
    self.animator.alphaValue = 0;
}
-(BOOL)visible {
    return self.alphaValue > 0;
}
-(void)mouseEntered:(NSEvent*)event {
    if(![self visible])
        return;
    
    self.animator.alphaValue = 1;
}
-(void)mouseExited:(NSEvent*)event {
    if(![self visible])
        return;
    
    [self show];
}
@end
