//
//  SMDrawButton.h
//  Snappy
//
//  Created by Fathy Boundjadj  on 24/12/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMButton.h"

typedef NS_ENUM(NSUInteger, SMDrawButtonState) {
    SMDrawButtonStateOff = 0,
    SMDrawButtonStateOn  = 1
};

@interface SMDrawButton : SMButton

@property (nonatomic) SMDrawButtonState btnState;

@end

