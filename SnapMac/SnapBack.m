//
//  SnapBack.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 11/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SnapBack.h"

WebScriptObject* SnapBackWSO = nil;


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
    [SnapBackWSO performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:JS waitUntilDone:NO];
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

