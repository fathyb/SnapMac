//
//  SMBezierPath.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 19/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMBezierPath.h"

@implementation NSBezierPath (Snappy)

-(CGPathRef)quartzPath {
    NSInteger i,
              numElements = [self elementCount];
    
    if (numElements > 0) {
        NSPoint points[3];

        CGMutablePathRef path = CGPathCreateMutable();
        BOOL didClosePath     = YES;
        
        for (i = 0; i < numElements; i++) {
            switch ([self elementAtIndex:i associatedPoints:points]) {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, nil, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, nil, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, nil, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        CGPathRef immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
        
        return immutablePath;
    }
    
    return nil;
}
@end