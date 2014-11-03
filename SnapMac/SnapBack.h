//
//  SnapBack.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 11/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#define Callback NSString*
extern WebScriptObject* SnapBackWSO;

void SnapCall(NSString* identifier, id firstArg, ...) NS_REQUIRES_NIL_TERMINATION;

#pragma mark JSON
NSString* objectToJSON(id object);
id objectToJS(id object);
id jsonToObject(NSString* data);