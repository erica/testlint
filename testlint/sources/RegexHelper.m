/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import "RegexHelper.h"

@implementation RegexHelper
+ (BOOL) testCaseSensitivePattern: (NSString *) searchPattern inString: (NSString *) string
{
    return [string rangeOfString:searchPattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionSearch].location != NSNotFound;
}

+ (BOOL) testPattern: (NSString *) searchPattern inString: (NSString *) string
{
    return [string rangeOfString:searchPattern options:NSRegularExpressionSearch].location != NSNotFound;
}

// Here for convenience.
+ (BOOL) testString: (NSString *) test inString: (NSString *) string
{
    return [string rangeOfString:test].location != NSNotFound;
}
@end
