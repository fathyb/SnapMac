//
//  SMConnection.m
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMConnection.h"
#include <CommonCrypto/CommonDigest.h>


#define kDefaultAPIServer @"https://feelinsonice-hrd.appspot.com"

@implementation SMConnection

+(NSString*)sha1ForString:(NSString*)string {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    NSData *stringBytes = [string dataUsingEncoding: NSUTF8StringEncoding];
    if(CC_SHA256(stringBytes.bytes, (CC_LONG)stringBytes.length, digest)) {
        NSMutableString* sha1 = NSMutableString.new;
        
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i)
            [sha1 appendFormat: @"%02x", digest[i]];
        
        return sha1;
    }
    return nil;
}
+(NSString*)tokenWithAuthToken:(NSString*)authToken {
    int timeStamp = (int)NSDate.date.timeIntervalSince1970;
    return [SMConnection tokenWithAuthToken:authToken andTimeStamp:timeStamp];
}
+(NSString*)tokenWithAuthToken:(NSString*)authToken andTimeStamp:(int)timestamp {
    NSString        *secret  = @"iEk21fuwZApXlz93750dmW22pw389dPwOk";
    NSString        *pattern = @"0001110111101110001111010101111011010001001110011000110001000110";
    NSMutableString *string = NSMutableString.new;
    NSDictionary    *hashes  = @{
                                 @"0" : [SMConnection sha1ForString:[NSString stringWithFormat:@"%@%@", secret, authToken]],
                                 @"1" : [SMConnection sha1ForString:[NSString stringWithFormat:@"%d%@", timestamp, secret]]
                                };
    
    for(int i = 0; i < pattern.length; i++) {
        NSString *c = [pattern substringWithRange:NSMakeRange(i, 1)];
        [string appendFormat:@"%@", [hashes[c] substringWithRange:NSMakeRange(i, 1)]];
    }
    return string.copy;
}
+(NSMutableDictionary*)genericData {
    return [SMConnection genericDataWithToken:@"m198sOkJEn37DjqZ32lpRu76xmw288xSQ9"];
}
+(NSMutableDictionary*)genericDataWithToken:(NSString*)token {
    int timeStamp = NSDate.date.timeIntervalSince1970;
    return @{
              @"timestamp"  : @(timeStamp),
              @"req_token"  : [SMConnection tokenWithAuthToken:token andTimeStamp:timeStamp],
              @"countryCode": @"fr-FR"
            }.mutableCopy;
}
@end
