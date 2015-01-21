//
//  SnappyFunction.h
//  Snappy
//
//  Created by Fathy Boundjadj  on 02/01/2015.
//  Copyright (c) 2015 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface SnappyFunction : NSObject

@property (nonatomic) JSObjectRef JSObject;
-(void)call;
-(void)call:(id)firstArg, ...;

@end

extern JSContextRef SMJSContext;

