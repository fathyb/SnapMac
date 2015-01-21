//
//  SnappyFunction.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 02/01/2015.
//  Copyright (c) 2015 Fathy B. All rights reserved.
//

#import "SnappyFunction.h"



JSValueRef NStoJS(id obj);
id JSToNS(JSValueRef obj);

@implementation SnappyFunction

-(void)call {
    return [self call:nil];
}
-(void)call:(id)firstArg, ... {
    JSValueRef exception = nil;
    
    if(!firstArg) {
        JSObjectCallAsFunction(SMJSContext,
                               self.JSObject,
                               nil,
                               0,
                               nil,
                               &exception);
        if(exception) {
            NSLog(@"Snappy Javascript runtime error");
            NSDictionary *result = JSToNS(exception);
            NSLog(@"Error in file %@ line %@ column %@", result[@"sourceURL"], result[@"line"], result[@"column"]);
        }
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
                           &exception);
    free(arguments);
    
    if(exception) {
        NSLog(@"Snappy Javascript runtime error");
        NSDictionary *result = JSToNS(exception);
        NSLog(@"Error in file %@ line %@ column %@", result[@"sourceURL"], result[@"line"], result[@"column"]);
    }
    return;
}

@end
