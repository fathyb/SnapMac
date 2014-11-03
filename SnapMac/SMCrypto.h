//
//  SMCrypto.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMCrypto : NSObject

+(id)decryptSnap:(NSData*)data;
+(id)encryptSnap:(NSData*)data;

@end
