//
//  SMWindow.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 07/11/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMWindow.h"

NSView* c(NSWindow* window) {
    return window.contentView;
}
@implementation SMWindow

-(void)setAppearance:(NSAppearance *)appearance {
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyChangeAppearance"
                                                      object:appearance];
    super.appearance = appearance;
    
    if(self.contentView)
        ((NSView*)self.contentView).appearance = appearance;
    
    if(self.webUI)
        self.webUI.appearance = appearance;
}

@end
