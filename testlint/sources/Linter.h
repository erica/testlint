/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import <Foundation/Foundation.h>

@interface Linter : NSObject
@property (nonatomic) BOOL encounteredErrors; // = NO
- (void) lint: (NSString *) path;
@end
