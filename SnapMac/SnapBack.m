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

JSContextRef ContexteJS = nil;



JSValueRef NStoJS(id ns) {
    if(!ns)
        return nil;
    
    JSValueRef jsObject = nil;
    
    NSDictionary* actions = @{
        @"String": ^(NSString *o) {
            JSStringRef jsString = JSStringCreateWithUTF8CString(o.UTF8String);
            JSValueRef  jsValue  = JSValueMakeString(ContexteJS,
                                                     jsString);
            JSStringRelease(jsString);
            
            return jsValue;
        },
        @"URL": ^(NSURL *o) {
            JSStringRef jsString = JSStringCreateWithUTF8CString(o.absoluteString.UTF8String);
            JSValueRef  jsValue  = JSValueMakeString(ContexteJS,
                                                     jsString);
            JSStringRelease(jsString);
            
            return jsValue;
        },
        @"Dictionary": ^(NSDictionary *o) {
            JSObjectRef object = JSObjectMake(ContexteJS, nil, nil);
            
            for(NSString *key in o.allKeys) {
                JSStringRef k     = JSStringCreateWithUTF8CString(key.UTF8String);
                JSObjectSetProperty(ContexteJS,
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
                return JSObjectMakeArray(ContexteJS,
                                         0,
                                         nil,
                                         nil);
            
            JSValueRef *values = calloc(o.count, sizeof(JSValueRef));
            
            for(int i = 0; i < o.count; i++)
                values[i] = NStoJS(o[i]);
            
            JSObjectRef jsArray = JSObjectMakeArray(ContexteJS,
                                                    o.count,
                                                    values,
                                                    nil);
            free(values);
            return jsArray;
        },
        @"Number": ^(NSNumber* o) {
            return JSValueMakeNumber(ContexteJS, o.doubleValue);
        },
        @"Boolean": ^(NSNumber *o) {
            return JSValueMakeBoolean(ContexteJS, o.boolValue);
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


@implementation WebScriptObject(Snappy)

-(void)call {
    return [self call:nil];
}
-(void)call:(id)firstArg, ... {
    if(!firstArg) {
        JSObjectCallAsFunction(ContexteJS,
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
    
    JSObjectCallAsFunction(ContexteJS,
                           self.JSObject,
                           nil,
                           length,
                           length == 1 ? &arguments[0] : arguments,
                           nil);
    free(arguments);
}

@end


