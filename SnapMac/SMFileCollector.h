//
//  SMFileCollector.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMFileCollector : NSObject

+(void)save:(NSString*)identifier withData:(NSData*)data andCallback:(SMCallback)callback;
+(void)urlsForMedia:(NSString*)media andCallback:(SMCallback)callback;

@end
