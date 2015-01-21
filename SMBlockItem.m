//
//  SMBlockItem.m
//  Snappy
//
//  Created by Fathy Boundjadj  on 11/11/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMBlockItem.h"

@interface SMBlockItem ()
- (void)_actionTriggered:(NSMenuItem *)theItem;
@end

@implementation SMBlockItem
@synthesize block;

- (id)initWithTitle:(NSString *)aString action:(SEL)aSelector keyEquivalent:(NSString *)charCode {
    return [self initWithTitle:aString block:nil keyEquivalent:charCode];
}

- (id)initWithTitle:(NSString *)aString block:(void (^)(NSMenuItem *item))aBlock keyEquivalent:(NSString *)charCode {
    if (self = [super initWithTitle:aString
                             action:@selector(_actionTriggered:)
                      keyEquivalent:charCode]) {
        [self setTarget:self];
        [self setBlock:aBlock];
    }
    return self;
}

- (void)_actionTriggered:(NSMenuItem *)theItem {
    if (theItem == self && self.block != nil)
        self.block(theItem);
}

@end