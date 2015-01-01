//
//  SMPhotoButton.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 14/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMButton.h"

IB_DESIGNABLE
@interface SMPhotoButton : SMButton

@property (nonatomic) BOOL down;
@property (nonatomic) BOOL dark;
@end
