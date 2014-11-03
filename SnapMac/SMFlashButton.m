//
//  SMFlashButton.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 19/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMFlashButton.h"

@implementation SMFlashButton

-(void)mouseDown:(NSEvent *)theEvent {
    self.flashState = ![self.image.name isEqualToString:NSImageNameStatusAvailable];
    [super mouseDown:theEvent];
}
-(void)setFlashState:(SMFlashState)flashState {
    _flashState = flashState;
    self.image  = [NSImage imageNamed:(self.flashState ? NSImageNameStatusAvailable : NSImageNameStatusUnavailable)];
}
@end
