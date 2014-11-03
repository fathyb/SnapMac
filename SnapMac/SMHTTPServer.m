//
//  SMHTTPServer.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 21/07/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMHTTPServer.h"

@implementation SMHTTPServer

@synthesize httpServer;

-(instancetype)init {
    if(self = [super init]) {
        httpServer = [HTTPServer new];
        
        [httpServer setConnectionClass:[SMHTTPConnection class]];
        [httpServer setType:@"_http._tcp."];
        [httpServer setPort:1250];
        [httpServer setConnectionClass:[SMHTTPConnection class]];
        
        NSError *error = nil;
        NSLog(@"Lancement du serveur...");
        if(![httpServer start:&error])
        {
            NSLog(@"Error starting HTTP Server: %@", error);
        }
    }
    return self;
}
@end
