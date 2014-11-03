//
//  SMPhotoToolsView.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 17/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMPhotoToolsView.h"

@implementation SMPhotoToolsView

-(void)awakeFromNib {
    SMFlashButton* flashBtn = [self flashBtn];
    flashBtn.target = self;
    flashBtn.action = @selector(toggleFlash:);
    
    CAShapeLayer* layer = [CAShapeLayer new];
    layer.fillColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.4);
    self.layer = layer;
    
    [SMSettings addOnloadBlock:^(SMSettings* settings) {
        _settings = settings;
        flashBtn.flashState = [[_settings objectForKey:@"SMUseFlash"] boolValue];
    }];
    
    self.cornerRadius = 20;
}

-(void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    [path moveToPoint:NSMakePoint(NSMaxX(_bounds), NSMinY(_bounds))];
    
    NSPoint bottomRightCorner = NSMakePoint(NSMaxX(_bounds), NSMaxY(_bounds));
    
    [path lineToPoint:NSMakePoint(NSMaxX(_bounds), NSMaxY(_bounds)-cornerRadius)];
    
    [path curveToPoint:NSMakePoint(NSMaxX(_bounds)-cornerRadius, NSMaxY(_bounds))
     
         controlPoint1:bottomRightCorner
     
         controlPoint2:bottomRightCorner];
    
    [path lineToPoint:NSMakePoint(NSMinX(_bounds), NSMaxY(_bounds))];
    
    [path lineToPoint:NSMakePoint(NSMinX(_bounds), NSMinY(_bounds))];
    
    [path lineToPoint:NSMakePoint(NSMaxX(_bounds), NSMinY(_bounds))];
    
    ((CAShapeLayer*)self.layer).path = [path quartzPath];
}

-(SMFlashButton*)flashBtn {
    return ((NSView*)self.subviews[0]).subviews[1];
}
-(void)toggleFlash:(SMFlashButton*)sender {
    [_settings setObject:@(sender.flashState) forKey:@"SMUseFlash"];
}

-(void)hide {
    self.animator.alphaValue = 0;
}
-(void)show {
    self.animator.alphaValue = 1;
}
@end
