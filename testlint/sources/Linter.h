/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import <Foundation/Foundation.h>

@interface Linter : NSObject
@property (nonatomic) BOOL encounteredErrors; // = NO
@property (nonatomic) BOOL enableAccessModifierChecks; // = NO
@property (nonatomic) BOOL skipStyleChecks; // = NO
@property (nonatomic) BOOL skipHygieneChecks; //  = NO;
@property (nonatomic) BOOL enableConstructors; //  = NO;
@property (nonatomic) BOOL enableUnwrapAndForcedCastCheck; //  = YES;
@property (nonatomic) BOOL enableAnalRetentiveColonCheck; //  = YES;
@property (nonatomic) BOOL enableSingleLineBraceAbuseCheck; //  = NO;
@property (nonatomic) BOOL enableAllmanCheck; //  = YES;

- (void) lint: (NSString *) path;
@end
