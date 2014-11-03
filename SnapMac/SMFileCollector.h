//
//  SMFileCollector.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMFileCollector : NSObject

+(NSString*)saveSnap:(NSString*)snap withData:(NSData*)data;

@end
