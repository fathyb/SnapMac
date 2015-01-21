//
//  SMPaintingLayer.h
//  Snappy
//
//  Created by Fathy Boundjadj  on 25/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface SMPaintingLayer : CALayer

@property (nonatomic) NSMutableArray *lines;

-(void)drawInImage:(NSImage*)img;
-(void)resizeTo:(NSSize)size;

@end
