//
//  SMPhotoOptsView.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 17/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMFlashButton.h"
#import "SMSettings.h"
#import <QuartzCore/QuartzCore.h>


IB_DESIGNABLE @interface SMPhotoOptsView : NSView

@property (nonatomic) IBInspectable CGFloat cornerRadius;

-(void)hide;
-(void)show;
@end
