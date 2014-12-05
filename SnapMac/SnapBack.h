//
//  SnapBack.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 11/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>


@interface WebScriptObject(Snappy)

-(void)call:(id)firstArg, ... NS_REQUIRES_NIL_TERMINATION;


@end
#define Callback NSString*
extern JSContextRef ContexteJS;

typedef WebScriptObject JSCallback;

