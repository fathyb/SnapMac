//
//  SnapBack.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 11/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import <JavaScriptCore/JSContext.h>
#import "SnapBack.h"
#import <objc/runtime.h>

JSContextRef SMJSContext = nil;

JSValueRef NStoJS(id ns) {
    if(!ns)
        return nil;
    
    JSValueRef jsObject = nil;
    
    NSDictionary* actions = @{
        @"String": ^(NSString *o) {
            JSStringRef jsString = JSStringCreateWithUTF8CString(o.UTF8String);
            JSValueRef  jsValue  = JSValueMakeString(SMJSContext,
                                                     jsString);
            JSStringRelease(jsString);
            
            return jsValue;
        },
        @"URL": ^(NSURL *o) {
            JSStringRef jsString = JSStringCreateWithUTF8CString(o.absoluteString.UTF8String);
            JSValueRef  jsValue  = JSValueMakeString(SMJSContext,
                                                     jsString);
            JSStringRelease(jsString);
            
            return jsValue;
        },
        @"Dictionary": ^(NSDictionary *o) {
            JSObjectRef object = JSObjectMake(SMJSContext, nil, nil);
            
            for(NSString *key in o.allKeys) {
                JSStringRef k     = JSStringCreateWithUTF8CString(key.UTF8String);
                JSObjectSetProperty(SMJSContext,
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
                return JSObjectMakeArray(SMJSContext,
                                         0,
                                         nil,
                                         nil);
            
            JSValueRef *values = calloc(o.count, sizeof(JSValueRef));
            
            for(int i = 0; i < o.count; i++)
                values[i] = NStoJS(o[i]);
            
            JSObjectRef jsArray = JSObjectMakeArray(SMJSContext,
                                                    o.count,
                                                    values,
                                                    nil);
            free(values);
            return jsArray;
        },
        @"Number": ^(NSNumber* o) {
            return JSValueMakeNumber(SMJSContext, o.doubleValue);
        },
        @"Boolean": ^(NSNumber *o) {
            return JSValueMakeBoolean(SMJSContext, o.boolValue);
        },
        @"WebScriptObject": ^(WebScriptObject *o) {
            return o.JSValue;
        }
    };
        
    JSObjectRef (^block)() = nil;
    NSString    *clsString = NSStringFromClass([ns class]);
    
    if(!clsString)
        return nil;
    
    for(id key in actions.allKeys) {
        if([clsString containsString:key])
            block = actions[key];
    }
    
    if(block)
        jsObject = block(ns);
    else
        NSLog(@"__jsValue_to_id(runtime) : unknown class [%@ class]", clsString);
    
    return jsObject;
}

id JSToNS(JSValueRef object) {
    
    JSType type = JSValueGetType(SMJSContext, object);
    id   result = nil;
    
    
    switch(type) {
        case kJSTypeObject:
            result = NSMutableDictionary.new;
            
            JSPropertyNameArrayRef props = JSObjectCopyPropertyNames(SMJSContext, (JSObjectRef)object);
            ssize_t            arraySize = JSPropertyNameArrayGetCount(props);
        
            for(ssize_t i = 0; i < arraySize; i++) {
                JSStringRef   k = JSPropertyNameArrayGetNameAtIndex(props, i);
                JSValueRef vval = JSObjectGetProperty(SMJSContext, (JSObjectRef)object, k, nil);
                NSString   *key = (NSString*)CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, k));
            
                result[key] = JSToNS(vval);
            
                JSStringRelease(k);
            }
            
            
            break;
    
        case kJSTypeString:
            ;
            JSStringRef jsStr = JSValueToStringCopy(SMJSContext, object, nil);
            result = (NSString*)CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, jsStr));
            JSStringRelease(jsStr);
            
            break;
        
        case kJSTypeBoolean:
            result = @(JSValueToBoolean(SMJSContext, object));
            break;
            
        case kJSTypeNumber:
            result = @(JSValueToNumber(SMJSContext, object, nil));
            break;
            
        default:
            NSLog(@"__id_to_jsValue(runtime) : unknown kJSType : %d", type);
        case kJSTypeNull:
        case kJSTypeUndefined:
            ;
            result = nil;
            break;
    }
    
    return result;
}


@implementation WebScriptObject(Snappy)

-(id)toObjCObject {
    return JSToNS(self.JSObject);
}

-(void)call {
    return [self call:nil];
}
-(void)call:(id)firstArg, ... {
    if(!firstArg) {
        JSObjectCallAsFunction(SMJSContext,
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
    
    JSObjectCallAsFunction(SMJSContext,
                           self.JSObject,
                           nil,
                           length,
                           length == 1 ? &arguments[0] : arguments,
                           nil);
    free(arguments);
}

@end


