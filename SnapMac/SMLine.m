//
//  SMLine.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 25/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMLine.h"

@implementation SMLine

@synthesize begin, end, color;

- (id)init {
    if (self = [super init])
        self.color = NSColor.blackColor.CGColor;
    
    return self;
}


@end
