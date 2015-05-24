/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import <Foundation/Foundation.h>

/*
 . (dot)	Any single character
 [abc] [^abc]	A single character of: a, b, or c | a single character except a, b, or c
 [a-z] [a-zA-Z]	Any single character in the range a-z | in the range a-z or A-Z
 ^ or \A	Start of line/string
 $ or \z	End of line/string
 \< or \>	Start of word or end of word
 \c	Control character
 \x \O	Hex/Octal digit
 \s \S	Any whitespace character / any non-whitespace character
 \d \D	Any digit / any non-digit
 \w \W	Any word character (letter, number, underscore) / any non-word character
 \b	Any word boundary
 \Q \E	Begin / end literal sequence
 (...)	Capture everything enclosed
 (a|b)	a or b
 a? a* a+	Zero or one of a | Zero or more of a | One or more of a
 a{3} a{3,} a{3,5}	Exactly 3 of a | 3 or more of a | 3, 4, or 5 of a
 [:upper:]	Upper case letters
 [:lower:]	Lower case letters
 [:alpha:]	All letters
 [:alnum:]	Digits and letters
 [:digit:]	Digits
 [:xdigit:]	Hexade­cimal digits
 [:punct:]	Punctu­ation
 [:blank:]	Space and tab
 [:space:]	Blank characters
 [:cntrl:]	Control characters
 [:graph:]	Printed characters
 [:print:]	Printed characters and spaces
 [:word:]	Digits, letters and underscore
*/

@interface RegexHelper : NSObject
+ (BOOL) testPattern: (NSString *) searchPattern inString: (NSString *) string;
+ (BOOL) testPatternCaseSensitive: (NSString *) searchPattern inString: (NSString *) string;
+ (BOOL) testString: (NSString *) test inString: (NSString *) string;
@end

