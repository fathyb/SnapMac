

#import "SnappyDictionary.h"


@implementation SnappyDictionary

- (id)initWithCapacity:(NSUInteger)capacity {
	self = super.init;
	if (self != nil) {
		dictionary = [NSMutableDictionary.alloc initWithCapacity:capacity];
		array = [NSMutableArray.alloc initWithCapacity:capacity];
	}
	return self;
}

- (id)copy {
	return [self mutableCopy];
}
-(NSArray*)allKeys {
    return array;
}
- (void)setObject:(id)anObject forKey:(id)aKey {
	if (![dictionary objectForKey:aKey])
		[array addObject:aKey];
    
	[dictionary setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey {
	[dictionary removeObjectForKey:aKey];
	[array removeObject:aKey];
}

- (NSUInteger)count {
	return [dictionary count];
}

- (id)objectForKey:(id)aKey {
	return [dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator {
	return [array objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator {
	return [array reverseObjectEnumerator];
}

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex {
	if ([dictionary objectForKey:aKey])
		[self removeObjectForKey:aKey];
        
	[array insertObject:aKey atIndex:anIndex];
	[dictionary setObject:anObject forKey:aKey];
}

- (id)keyAtIndex:(NSUInteger)anIndex {
	return [array objectAtIndex:anIndex];
}

@end
