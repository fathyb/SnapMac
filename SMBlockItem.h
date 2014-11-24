//
//  SMBlockItem.h
//  Snappy
//
//  Created by Fathy Boundjadj  on 11/11/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMBlockItem : NSMenuItem {
    void (^block)(NSMenuItem *item);
}

@property (copy, readwrite) void (^block)(NSMenuItem *item);

- (id)initWithTitle:(NSString *)aString block:(void (^)(NSMenuItem *item))aBlock keyEquivalent:(NSString *)charCode;

@end