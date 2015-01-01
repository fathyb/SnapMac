//
//  SMPaintingLayer.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 25/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMPaintingLayer.h"
#import "SMLine.h"

@implementation SMPaintingLayer

-(instancetype)init {
    if((self = super.init)) {
        [self clear];
        self.delegate = self;
        
    }
    
    return self;
}
-(void)drawInImage:(NSImage*)img {
    [self resizeTo:img.size];
    
    [img lockFocus];
    
    [self drawLayer:self
          inContext:isYosemite() ? NSGraphicsContext.currentContext.CGContext : NSGraphicsContext.currentContext.graphicsPort];
    
    [img unlockFocus];
}
-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)ctx {
    CGContextSetLineWidth(ctx, 5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    [NSColor.redColor set];
    
    CGPoint begin, end;
    
    for(SMLine *line in self.lines) {
        begin = line.begin;
        end   = line.end;
        CGContextBeginPath(ctx);
        CGContextSetStrokeColorWithColor(ctx, line.color);
        CGContextMoveToPoint(ctx, begin.x, begin.y);
        CGContextAddLineToPoint(ctx, end.x, end.y);
        CGContextStrokePath(ctx);
    }
    
}
-(void)resizeTo:(NSSize)size {
    CGFloat factor = size.width / self.frame.size.width;
    
    for(SMLine *line in self.lines) {
        line.begin = NSMakePoint(line.begin.x * factor, line.begin.y * factor);
        line.end   = NSMakePoint(line.end  .x * factor, line.end  .y * factor);
    }
    
    self.frame = NSMakeRect(0, 0, size.width, size.height);
    [self setNeedsDisplay];
}
-(void)clear {
    self.lines = NSMutableArray.new;
    [self setNeedsDisplay];
}

@end
