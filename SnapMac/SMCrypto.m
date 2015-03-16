//
//  SMCrypto.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMCrypto.h"

@implementation SMCrypto

NSString *encryptKey = @"M02cnQ51Ji97vwT4";
NSString *domain     = @"com.fathyb.snappy";



+(id) AES:(NSData*)data
      key:(NSData*)key
       iv:(NSData*)iv
  options:(CCOptions)options
operation:(CCOperation)operation {
    
    BOOL         encrypt = operation == kCCEncrypt;
    id            result = nil;
    void      *strBuffer = nil;
    size_t decryptedSize = 0;
    ssize_t   bufferSize = data.length;
    
    if(encrypt) {
        bufferSize += 16;
         strBuffer  = malloc(bufferSize);
        
        bzero(strBuffer, bufferSize);
        [data getBytes:strBuffer
                length:bufferSize];
    }
    
    void *buffer = malloc(bufferSize);
    
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          options,
                                          key.bytes,
                                          key.length,
                                          iv.bytes,
                                          encrypt ? strBuffer : data.bytes,
                                          bufferSize,
                                          buffer,
                                          bufferSize,
                                          &decryptedSize);
    
    if(strBuffer)
        free(strBuffer);
    
    if(cryptStatus == kCCSuccess)
        result = [NSData dataWithBytesNoCopy:buffer
                                      length:decryptedSize];
    else {
        result = [NSError errorWithDomain:domain
                                     code:cryptStatus
                                 userInfo:nil];
        free(buffer);
    }
    
    return result;
}


+(id)decryptSnap:(NSData*)data {
    return [SMCrypto AES:data
                     key:[encryptKey dataUsingEncoding:NSUTF8StringEncoding]
                      iv:nil
                 options:kCCOptionECBMode | kCCOptionPKCS7Padding
               operation:kCCDecrypt];
}
+(id)encryptSnap:(NSData*)data {
    
    NSMutableData *tmpData		= data.mutableCopy;
    int blockSize				= 16;
    int charDiv					= blockSize-((tmpData.length + 1) % blockSize);
    NSMutableString *padding	= [NSMutableString.alloc initWithFormat:@"%c", (unichar)10];
        
    for (int i = 0; i < charDiv; i++)
        [padding appendFormat:@"%c", (unichar)charDiv];
    
    [tmpData appendData:[padding dataUsingEncoding:NSUTF8StringEncoding]];

    return [SMCrypto AES:tmpData
                     key:[encryptKey dataUsingEncoding:NSUTF8StringEncoding]
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
