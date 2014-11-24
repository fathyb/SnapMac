//
//  SnapBack.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 11/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//
#import <JavaScriptCore/JavaScriptCore.h>
#import "SnapBack.h"
#import <objc/runtime.h>

#define iObject(T) _Generic( (T), id: YES, default: NO)
#define isObject(x) ( strchr("@#", @encode(typeof(x))[0]) != NULL )

WebView* SBWebView = nil;

#pragma mark JSON


NSString* snapback_quoter(NSString* string) {
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return [NSString stringWithFormat:@"\"%@\"", string];
}
NSString* objectToJSON(id object) {
    NSError* error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
id objectToJS(id object) {
    id data = object;
    
    NSDictionary* actions = @{
        @"NSString": ^(id o) {
            return snapback_quoter(o);
        },
        @"NSURL": ^(id o) {
            return snapback_quoter([((NSURL*)o) absoluteString]);
        },
        @"NSDictionary": ^(id o) {
            return [NSString stringWithFormat:@"JSON.parse(%@)", snapback_quoter(objectToJSON(o))];
        },
        @"NSArray": ^(id o) {
            return [NSString stringWithFormat:@"JSON.parse(%@)", snapback_quoter(objectToJSON(o))];
        }
    };
    
    NSString* (^block)()  = nil;
    
    for(id key in actions.allKeys)
        if([object isKindOfClass:NSClassFromString(key)])
            block = actions[key];
    
    if(block) data = block(object);
    
    return data;
}
id jsonToObject(NSString* data) {
    NSError* error;
    id obj = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    return obj;
}

#pragma mark SnapCall


void evalJS(NSString* JS) {
    [SBWebView.windowScriptObject performSelectorOnMainThread:@selector(evaluateWebScript:)
                                                   withObject:JS
                                                waitUntilDone:NO];
}

JSValueRef NStoJS(id ns) {
    if(!ns)
        return nil;
    
    JSValueRef jsObject = nil;
    
    NSDictionary* actions = @{
        @"String": ^(NSString *o) {
            JSStringRef jsString = JSStringCreateWithUTF8CString(o.UTF8String);
            JSValueRef  jsValue  = JSValueMakeString(SBWebView.mainFrame.globalContext,
                                                     jsString);
            JSStringRelease(jsString);
            
            return jsValue;
        },
        @"URL": ^(NSURL *o) {
            JSStringRef jsString = JSStringCreateWithUTF8CString(o.absoluteString.UTF8String);
            JSValueRef  jsValue  = JSValueMakeString(SBWebView.mainFrame.globalContext,
                                                     jsString);
            JSStringRelease(jsString);
            
            return jsValue;
        },
        @"Dictionary": ^(NSDictionary *o) {
            JSObjectRef object = JSObjectMake(SBWebView.mainFrame.globalContext, nil, nil);
            
            for(NSString *key in o.allKeys) {
                JSStringRef k     = JSStringCreateWithUTF8CString(key.UTF8String);
                JSObjectSetProperty(SBWebView.mainFrame.globalContext,
                                    object,
                                    k,
                                    NStoJS(o[key]),
                                    kJSPropertyAttributeNone,
                                    nil);
                JSStringRelease(k);
            }
            
            return object;
        },
        @"Array": ^(NSArray *o) {
            if(!o.count)
                return JSObjectMakeArray(SBWebView.mainFrame.globalContext,
                                         0,
                                         nil,
                                         nil);
            
            JSValueRef *values = calloc(o.count, sizeof(JSValueRef));
            
            for(int i = 0; i < o.count; i++)
                values[i] = NStoJS(o[i]);
            
            JSObjectRef jsArray = JSObjectMakeArray(SBWebView.mainFrame.globalContext,
                                                    o.count,
                                                    values,
                                                    nil);
            free(values);
            return jsArray;
        },
        @"Number": ^(NSNumber* o) {
            return JSValueMakeNumber(SBWebView.mainFrame.globalContext, o.doubleValue);
        },
        @"Boolean": ^(NSNumber *o) {
            return JSValueMakeBoolean(SBWebView.mainFrame.globalContext, o.boolValue);
        }
    };
        
    JSObjectRef (^block)()  = nil;
    
    
    
    NSString *clsString = NSStringFromClass([ns class]);
    
    if(!clsString)
        return nil;
    
    for(id key in actions.allKeys) {
        if([clsString containsString:key])
            block = actions[key];
    }
    
    if(block)
        jsObject = block(ns);
    else
        NSLog(@"unknown class %@", clsString);
    
    return jsObject;
}

void SnapCall(NSString* identifier, id firstArg, ...) {
    va_list argumentList;
    va_start(argumentList, firstArg);
    
    NSMutableString *callStr = [NSMutableString stringWithFormat:@"SnapCall(%@).call(%@", snapback_quoter(identifier), objectToJS(firstArg)];
    
    id currentObj;
    
    while((currentObj = va_arg(argumentList, id)))
        if(currentObj)
            [callStr appendString:[NSString stringWithFormat:@", %@", objectToJS(currentObj)]];
    
    [callStr appendString:@");"];
    
    evalJS(callStr);
    
    va_end(argumentList);
    
}







@implementation WebScriptObject(Snappy)

-(void)call {
    return [self call:nil];
}
-(void)call:(id)firstArg, ... {
    NSLog(@"Connecting to JavaSciptCore Runtime");
    if(!firstArg) {
        JSObjectCallAsFunction(SBWebView.mainFrame.globalContext,
                               self.JSObject,
                               nil,
                               0,
                               nil,
                               nil);
        return;
    }
    id  argument = nil;
    int length   = 1,
        i        = 1;
    
    va_list argumentList;
    va_start(argumentList, firstArg);
    
    while(va_arg(argumentList, id))
        length++;
    
    va_end(argumentList);
    va_start(argumentList, firstArg);
    
    JSValueRef *arguments    = calloc(length, sizeof(JSValueRef));
                arguments[0] = NStoJS(firstArg);
    
    while((argument = va_arg(argumentList, id))) {
        arguments[i] = NStoJS(argument);
        i++;
    }
    
    va_end(argumentList);
    
    JSObjectCallAsFunction(SBWebView.mainFrame.globalContext,
                           self.JSObject,
                           nil,
                           length,
                           length == 1 ? &arguments[0] : arguments,
                           nil);
    free(arguments);
}

@end


