//
//  SMButton.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 16/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>

IB_DESIGNABLE
@interface SMButton : NSButton

@property (nonatomic) NSColor *backgroundColor;
@property (nonatomic) NSAppearance *smAppearance;

-(BOOL)visible;
-(void)show;
-(void)hide;

@end
