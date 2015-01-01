//
//  SMColorPickerButton.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 25/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMColorPickerButton.h"

@implementation SMColorPickerButton

-(void)awakeFromNib {
    [super awakeFromNib];
    self.colorPanel = NSColorPanel.new;
    self.colorPanel.target = self;
    self.colorPanel.action = @selector(colorUpdate:);
    [self.colorPanel performClose:self];
    
    self.btnState = NO;
}
-(void)mouseDown:(NSEvent *)theEvent {
    self.btnState = !self.btnState;
    
    self.colorPanel.isVisible ? [self.colorPanel orderOut:nil] : [self.colorPanel orderFront:nil];
}
-(void)colorUpdate:(NSColorPanel*)colorPanel {
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyChangeDrawingColor"
                                                      object:colorPanel.color];
}
@end
