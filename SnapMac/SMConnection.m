//
//  SMConnection.m
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMConnection.h"
#include <CommonCrypto/CommonDigest.h>

#import "ASIFormDataRequest.h"

static NSString *kDefaultAPIServer = @"https://feelinsonice-hrd.appspot.com";

@implementation SMConnection

+(NSString*)sha1ForString:(NSString*)string {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    NSData *stringBytes = [string dataUsingEncoding: NSUTF8StringEncoding];
    if(CC_SHA256([stringBytes bytes], (CC_LONG)[stringBytes length], digest)) {
        NSMutableString* sha1 = [[NSMutableString alloc] init];
        for (int i = 0 ; i < CC_SHA256_DIGEST_LENGTH ; ++i){
            [sha1 appendFormat: @"%02x", digest[i]];
        }
        return sha1;
    }
    return nil;
}
+(NSString*)tokenWithAuthToken:(NSString*)authToken {
    int timeStamp = (int)[[NSDate date] timeIntervalSince1970];
    return [SMConnection tokenWithAuthToken:authToken andTimeStamp:timeStamp];
}
+(NSString*)tokenWithAuthToken:(NSString*)authToken andTimeStamp:(int)timestamp {
    NSString *secret = @"iEk21fuwZApXlz93750dmW22pw389dPwOk";
    NSString *pattern = @"0001110111101110001111010101111011010001001110011000110001000110";
    NSDictionary *hashes = @{
        @"0" : [SMConnection sha1ForString:[NSString stringWithFormat:@"%@%@", secret, authToken]],
        @"1" : [SMConnection sha1ForString:[NSString stringWithFormat:@"%d%@", timestamp, secret]]
    };
    NSMutableString *string = [NSMutableString new];
    for(int i = 0; i < [pattern length]; i++) {
        NSString *c = [pattern substringWithRange:NSMakeRange(i, 1)];
        [string appendFormat:@"%@", [hashes[c] substringWithRange:NSMakeRange(i, 1)]];
    }
    return [string copy];
}
+(NSMutableDictionary*)genericData {
    return [SMConnection genericDataWithToken:@"m198sOkJEn37DjqZ32lpRu76xmw288xSQ9"];
}
+(NSMutableDictionary*)genericDataWithToken:(NSString*)token {
    int timeStamp = (int)[[NSDate date] timeIntervalSince1970];
    return [@{
              @"timestamp": [NSString stringWithFormat:@"%d", timeStamp],
              @"req_token": [SMConnection tokenWithAuthToken:token andTimeStamp:timeStamp],
              @"version" : @"4.1.07",
              @"countryCode": @"fr-FR"
            } mutableCopy];
}
+(void)getDataRequestToURL:(NSString*)urlString andCallback:(SMCallback)block {
    NSURL *url = [NSURL URLWithString:urlString relativeToURL:[NSURL URLWithString:kDefaultAPIServer]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request startSynchronous];
        NSError *error = [request error];
        if (!error) {
            block([request responseData]);
        }
    });
}
+(void)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict andCallback:(SMCallback)block {
    [self requestToURL:urlString withData:dict andCallback:block asData:NO];
}

+(void)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict andCallback:(SMCallback)block asData:(BOOL)asData {  
    NSURL *url = [NSURL URLWithString:urlString relativeToURL:[NSURL URLWithString:kDefaultAPIServer]];
    
    __block ASIFormDataRequest* request;
    
    if(dict) {
        request = [ASIFormDataRequest requestWithURL:url];
        for(id key in dict) {
            id value = dict[key];
            if([value isKindOfClass:[NSData class]]) {
                [request addData:value forKey:key];
                [request addRequestHeader:@"Content-type" value:@"multipart/form-data"];
            }
            else {
                [request setPostValue:value forKey:key];
            }
        }
    }
    else {
        request = [ASIHTTPRequest requestWithURL:url];
    }
    
    [request setCompletionBlock:^{
        NSLog(@"Request = %@", request);
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [request startSynchronous];
        NSError *error = request.error;
        if (!error)
            block(asData ? request.responseData : request.responseString);
        else
            block(error);
    });
}
+(id)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict asData:(BOOL)asData {
    NSURL *url = [NSURL URLWithString:urlString relativeToURL:[NSURL URLWithString:kDefaultAPIServer]];
    NSLog(@"Connection à %@", url);
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    for(id key in dict) {
        id value = [dict objectForKey:key];
        [request setPostValue:value forKey:key];
    }
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        return (asData ? [request responseData] : [request responseString]);
    }
    return nil;
}

+(NSString*)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict {
    return [SMConnection requestToURL:urlString withData:dict asData:NO];
}

@end
