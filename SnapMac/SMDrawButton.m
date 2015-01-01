//
//  SMDrawButton.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 24/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMDrawButton.h"

@implementation SMDrawButton
@synthesize btnState;

-(void)mouseDown:(NSEvent*)event {
    if(!self.alphaValue)
        return;
    
    self.btnState = !self.btnState;
    
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyToggleDrawing"
                                                      object:@(self.btnState)];
}
-(void)show {
    [super show];
    self.btnState = SMDrawButtonStateOff;
}
-(void)setBtnState:(SMDrawButtonState)fbtnState {
    btnState = fbtnState;
    
    self.image = [NSImage imageNamed:@(btnState ? "CrayonAlternate" : "Crayon")];
    self.alternateImage = [NSImage imageNamed:@(btnState ? "Crayon" : "CrayonAlternate")];
    
}
@end
