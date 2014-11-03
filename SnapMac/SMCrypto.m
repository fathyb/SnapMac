//
//  SMCrypto.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMCrypto.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation SMCrypto

NSString* encryptKey = @"M02cnQ51Ji97vwT4";
NSString* domain = @"com.fathyb.snappy";

+(id)SnapCrypt:(CCOperation)operation forData:(NSData*)data {
    //encrypt size_t bufferSize = [data length] +  kCCKeySizeAES128;
    NSData* encryptionKey = [encryptKey dataUsingEncoding:NSASCIIStringEncoding];
    void*   buffer        = malloc(data.length);
    size_t  decryptedSize = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          kCCOptionECBMode,
                                          encryptionKey.bytes,
                                          encryptionKey.length,
                                          nil,
                                          data.bytes,
                                          data.length,
                                          buffer,
                                          data.length,
                                          &decryptedSize);
    
    if (cryptStatus == kCCSuccess)
        return [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    else
        return [NSError errorWithDomain:domain code:cryptStatus userInfo:nil];
}
+(id)decryptSnap:(NSData*)data {
    return [SMCrypto SnapCrypt:kCCDecrypt forData:data];
}
+(id)encryptSnap:(NSData*)data {
    return [SMCrypto SnapCrypt:kCCDecrypt forData:data];
}
@end
