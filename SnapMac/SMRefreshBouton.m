//
//  SMRefreshBouton.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 06/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMRefreshBouton.h"

@implementation SMRefreshBouton

-(void)mouseDown:(NSEvent *)theEvent {
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyRefreshVideo"
                                                      object:nil];
}
@end
