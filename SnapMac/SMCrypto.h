//
//  SMCrypto.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface SMCrypto : NSObject

+(id) AES:(NSData*)data
      key:(NSData*)key
       iv:(NSData*)iv
  options:(CCOptions)options
operation:(CCOperation)operation;

+(id)decryptSnap:(NSData*)data;
+(id)encryptSnap:(NSData*)data;

+(id)decryptStory:(NSData*)data withKey:(NSData*)key andIv:(NSData*)iv;
+(id)encryptStory:(NSData*)data withKey:(NSData*)key andIv:(NSData*)iv;

@end
