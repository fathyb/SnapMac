//
//  SMUndoDrawButton.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 27/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMUndoDrawButton.h"

@implementation SMUndoDrawButton

-(void)mouseDown:(NSEvent *)theEvent {
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyUndoDirtyDraw"
                                                      object:nil];
}

@end
