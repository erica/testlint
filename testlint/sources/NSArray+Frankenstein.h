/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import <Foundation/Foundation.h>

typedef id (^MapBlock)(id object);
typedef BOOL (^TestingBlock)(id object);
typedef void (^DoBlock)(id object);

#pragma mark - Utility
@interface NSArray (Frankenstein)
@property (nonatomic, readonly) id car;
@property (nonatomic, readonly) NSArray *cdr;
@property (nonatomic, readonly) NSArray *reversed;
- (NSArray *) map: (MapBlock) aBlock;
- (NSArray *) collect: (TestingBlock) aBlock;
- (NSArray *) reject: (TestingBlock) aBlock;
- (void) performBlock: (DoBlock) aBlock;
@end
