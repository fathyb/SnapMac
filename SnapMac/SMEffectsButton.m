//
//  SMEffectsButton.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 30/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMEffectsButton.h"

@implementation SMEffectsButton

-(void)awakeFromNib {
    [super awakeFromNib];
    [NSNotificationCenter.defaultCenter addObserverForName:@"SnappyChangeAppearance"
                                                    object:nil
                                                     queue:NSOperationQueue.mainQueue
                                                usingBlock:^(NSNotification* notif) {
                                                    //self.appearance = notif.object;
    }];
}

@end
