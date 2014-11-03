//
//  SMFlashButton.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 19/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMButton.h"

typedef NS_ENUM(NSUInteger, SMFlashState) {
    SMFlashOff = 0,
    SMFlashOn  = 1
};

@interface SMFlashButton : SMButton

@property (nonatomic) SMFlashState flashState;

@end
