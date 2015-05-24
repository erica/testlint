/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import "NSArray+Frankenstein.h"

@implementation NSArray (Frankenstein)

- (NSArray *) reversed
{
    return [[self reverseObjectEnumerator] allObjects];
}

- (id) car
{
    if (self.count == 0) return nil;
    return self[0];
}

- (NSArray *) cdr
{
    if (self.count < 2) return nil;
    return [self subarrayWithRange:NSMakeRange(1, self.count - 1)];
}

- (NSArray *) map: (MapBlock) aBlock
{
    if (!aBlock) return self;
    
    NSMutableArray *resultArray = [NSMutableArray array];
    for (id object in self)
    {
        id result = aBlock(object);
        [resultArray addObject: result ? : [NSNull null]];
    }
    return [resultArray copy];
}

- (NSArray *) collect: (TestingBlock) aBlock
{
    if (!aBlock) return self;
    
    NSMutableArray *resultArray = [NSMutableArray array];
    for (id object in self)
    {
        BOOL result = aBlock(object);
        if (result)
            [resultArray addObject:object];
    }
    return [resultArray copy];
}

- (NSArray *) reject: (TestingBlock) aBlock
{
    if (!aBlock) return self;
    
    NSMutableArray *resultArray = [NSMutableArray array];
    for (id object in self)
    {
        BOOL result = aBlock(object);
        if (!result)
            [resultArray addObject:object];
    }
    return [resultArray copy];
}

- (void) performBlock: (DoBlock) aBlock
{
    if (!aBlock) return;
    for (id object in self)
    {
        aBlock(object);
    }
}
@end
