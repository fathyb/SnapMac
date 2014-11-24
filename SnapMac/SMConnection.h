//
//  SMConnection.h
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SMConnection : NSObject <NSURLConnectionDelegate>

+(NSString*)sha1ForString:(NSString*)string;
+(NSString*)tokenWithAuthToken:(NSString*)authToken;
+(NSString*)tokenWithAuthToken:(NSString*)authToken andTimeStamp:(int)timestamp;
+(void)getDataRequestToURL:(NSString*)urlString andCallback:(SMCallback)block;
+(void)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict andCallback:(SMCallback)block;
+(void)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict andCallback:(SMCallback)block asData:(BOOL)asData;
+(NSString*)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict;
+(id)requestToURL:(NSString*)urlString withData:(NSDictionary*)dict asData:(BOOL)asData;
+(NSMutableDictionary*)genericData;
+(NSMutableDictionary*)genericDataWithToken:(NSString*)token;

@end
