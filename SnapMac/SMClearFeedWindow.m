//
//  SMClearFeedWindow.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 28/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMClearFeedWindow.h"
#import "Snappy.h"

@implementation SMClearFeedWindow

-(instancetype)init {
    if((self = super.init)) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(show:)
                                                   name:@"SnappyShowClearFeedDialog"
                                                 object:nil];
        [NSBundle.mainBundle loadNibNamed:@"Clear Feed"
                                    owner:self
                          topLevelObjects:nil];
     }
     
     return self;
}

-(void)show:(NSNotification*)notif {
    [NSApp beginSheet:_window
       modalForWindow:((Snappy*)NSApplication.sharedApplication.delegate).window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}
- (IBAction)hide:(id)sender {
    [NSApp endSheet:_window];
    [_window orderOut:nil];
}
- (IBAction)clearFeed:(id)sender {
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyClearUserFeed"
                                                      object:nil];
    [self hide:self];
}

@end
