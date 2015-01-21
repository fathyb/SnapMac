//
//  SMTimerLayer.h
//  Snappy
//
//  Created by Fathy Boundjadj  on 17/01/2015.
//  Copyright (c) 2015 Fathy B. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface SMTimerLayer : CALayer

@property (nonatomic) NSColor *color;
@property (nonatomic) CGFloat progress;
@property (nonatomic) CGFloat timeout;
@property (nonatomic) NSTimeInterval *timer;
@property (nonatomic) CATextLayer *label;

-(void)launchWithTimeout:(CGFloat)timeout;


@end
