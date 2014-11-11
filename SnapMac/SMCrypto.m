//
//  SMCrypto.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMCrypto.h"

@implementation SMCrypto

NSString* encryptKey = @"M02cnQ51Ji97vwT4";
NSString* domain = @"com.fathyb.snappy";



+(id) AES:(NSData*)data
      key:(NSData*)key
       iv:(NSData*)iv
  options:(CCOptions)options
operation:(CCOperation)operation {
    
    id     result        = nil;
    void*  buffer        = malloc(data.length);
    size_t decryptedSize = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          options,
                                          key.bytes,
                                          key.length,
                                          iv.bytes,
                                          data.bytes,
                                          data.length,
                                          buffer,
                                          data.length,
                                          &decryptedSize);
                                   
    if(cryptStatus == kCCSuccess)
        result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    else {
        result = [NSError errorWithDomain:domain code:cryptStatus userInfo:nil];
        free(buffer);
    }
    
    return result;
}


+(id)decryptSnap:(NSData*)data {
    return [SMCrypto AES:data
                     key:[encryptKey dataUsingEncoding:NSASCIIStringEncoding]
                      iv:nil
                 options:kCCOptionECBMode
               operation:kCCDecrypt];
}
+(id)encryptSnap:(NSData*)data {
    return [SMCrypto AES:data
                     key:[encryptKey dataUsingEncoding:NSASCIIStringEncoding]
                      iv:nil
                 options:kCCOptionECBMode
               operation:kCCEncrypt];
}


+(id)decryptStory:(NSData*)data withKey:(NSData*)key andIv:(NSData*)iv {
    return [SMCrypto AES:data
                     key:key
                      iv:iv
                 options:kCCOptionPKCS7Padding
               operation:kCCDecrypt];
}
+(id)encryptStory:(NSData*)data withKey:(NSData*)key andIv:(NSData*)iv {
    return [SMCrypto AES:data
                     key:key
                      iv:iv
                 options:kCCOptionPKCS7Padding
               operation:kCCEncrypt];
}

@end
