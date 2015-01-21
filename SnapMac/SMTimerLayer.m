//
//  SMTimerLayer.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 17/01/2015.
//  Copyright (c) 2015 Fathy B. All rights reserved.
//

#import "SMTimerLayer.h"

int start = 0;

@implementation SMTimerLayer

-(instancetype)init {
    if((self = super.init)) {
        self.delegate = self;
        self.cornerRadius = 25;
        self.backgroundColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.7].CGColor;
        self.label = CATextLayer.new;
        self.label.font = (__bridge CFTypeRef)(@"Helvetica-Light");
        self.label.fontSize = 20;
        self.label.wrapped = YES;
        self.label.frame = NSMakeRect(0, -12, 50, 50);
        self.label.string = @"0";
        self.label.alignmentMode = kCAAlignmentCenter;
        self.label.foregroundColor = [NSColor colorWithCalibratedWhite:.8 alpha:1].CGColor;
        [self addSublayer:self.label];

        [self clear];
    }
    return self;
}
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    CGRect rect    = self.frame;
    NSColor *color = self.color;
    
    CGContextSetRGBStrokeColor(context, color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent);
    CGContextSetLineWidth(context, 2);
    
    CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
    CGFloat radius = (rect.size.width - 4) / 2,
            startAngle = M_PI_2,
            endAngle = (self.progress * 2 * M_PI) + startAngle;
    
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, NO);
    CGContextDrawPath(context, kCGPathStroke);
}
-(void)launchWithTimeout:(CGFloat)timeout {
    self.color = [NSColor colorWithCalibratedRed:255 green:255 blue:255 alpha:1];
    start = NSDate.date.timeIntervalSince1970;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        do {
            CGFloat seconds = (NSDate.date.timeIntervalSince1970 - start);
            self.progress = seconds/timeout;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelectorOnMainThread:@selector(setNeedsDisplay)
                                       withObject:nil
                                    waitUntilDone:YES];
                
                self.label.string = [NSString stringWithFormat:@"%d", (int)round(timeout-seconds)];
            });
            usleep(1000000/60);
        } while(self.progress < 1);
    });
}
-(void)clear {
    self.progress = 0;
    [self setNeedsDisplay];
}
@end
