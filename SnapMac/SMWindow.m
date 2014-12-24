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
    super.appearance = appearance;
    
    if(self.contentView)
        c(self).appearance = appearance;
    
    if(self.settingsWindow) {
        c(self.settingsWindow).appearance = appearance;
          self.settingsWindow .appearance = appearance;
    }
    
    if(self.webUI)
        self.webUI.appearance = appearance;
    
    if(self.aboutWindow) {
        c(self.aboutWindow).appearance = appearance;
          self.aboutWindow .appearance = appearance;
    }
    
}

@end
