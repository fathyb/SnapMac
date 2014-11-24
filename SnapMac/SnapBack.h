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
extern WebView* SBWebView;

typedef WebScriptObject JSCallback;

void SnapCall(NSString* identifier, id firstArg, ...) NS_REQUIRES_NIL_TERMINATION;
void SnappyCallback(JSCallback *object, ...) NS_REQUIRES_NIL_TERMINATION;

#pragma mark JSON
NSString* objectToJSON(id object);
id objectToJS(id object);
id jsonToObject(NSString* data);