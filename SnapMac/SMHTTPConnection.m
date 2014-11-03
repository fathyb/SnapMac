//
//  SMHTTPConnection.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 21/07/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMHTTPConnection.h"
#import "HTTPDataResponse.h"

@implementation SMHTTPConnection

- (NSObject<HTTPResponse>*)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    NSLog(@"Connection entrante... %@", path);
    
    if([path hasPrefix:@"/getSnap?"]) {
        NSString *req = [path substringWithRange:NSMakeRange(9, path.length-9)];
        NSArray *reqs = [req componentsSeparatedByString:@"&"];
        NSMutableDictionary *parametres = [NSMutableDictionary new];
        for(NSString *param in reqs) {
            NSArray *params = [param componentsSeparatedByString:@"="];
            if(params.count != 2)
                break;
            [parametres setObject:params[1] forKey:params[0]];
        }
        if(!parametres[@"id"] || !parametres[@"auth-token"]) return defaultResponse();
        NSString *authToken = parametres[@"auth-token"];
        //NSString *snapId = parametres[@"id"];
        SMClient *client = [SMClient sharedClient];
        if(![authToken isEqualToString:[client authToken]])
            return textResponse(@"The authentification token is invalid.");
    }
    return defaultResponse();
}
//data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==
NSObject<HTTPResponse>* emptyImage() {
    return outputData([NSData dataWithContentsOfURL:[NSURL URLWithString:@"data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="]]);
}
NSObject<HTTPResponse>* defaultResponse() {
    return textResponse(@"Hi, I'm the SnapMac Server, my job is to decrypt your snaps to send them to SnapMac application. But, in fact, you must not see this, so if you have any question feel free to contact me at <a href='mailto:admin@fathyb.fr'>admin@fathyb.fr</a> :)");
}
NSObject<HTTPResponse>* textResponse(NSString *text) {
    NSString *response = [NSString stringWithFormat:@"<!DOCTYPE html>"
    "<html><head>"
    "<style>body {font-family:'Helvetica Neue'; text-align: center;}</style>"
    "<title>SnapMac Server</title></head><body><p>%@</p></body></html>", text];
    return outputString(response);
}
NSObject<HTTPResponse>* outputString(NSString *string) {
    return outputData([string dataUsingEncoding:NSUTF8StringEncoding]);
}

NSObject<HTTPResponse>* outputData(NSData *data) {
    return [[HTTPDataResponse alloc] initWithData:data];
}
@end
