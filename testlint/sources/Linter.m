/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import "Linter.h"
#import "Utility.h"
#import "NSArray+Frankenstein.h"
#import "RegexHelper.h"

/*
 
 To explore:
 - verbosity for anonymous types $0 vs something in
 - title case for enum variants
 - title case for global scope and types
 - overly long names?
 - avoiding i, j, k, tmp
 - excessive nesting
 - giant statements
 - protocol beautification
 - protocol single-letter abuse vs meaningful names
 - missing access modifiers? access modifier scan?
 - De Morgan's law check? (probably not)
 
 */

@implementation Linter

#pragma mark - Init

- (instancetype) init
{
    if (!(self = [super init])) return self;
    _encounteredErrors = NO;
    return self;
}

#pragma mark - Delintage

- (void) lint: (NSString *) path
{
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!string) return;
    
//    BOOL topLevel = [string containsString:@"@UIApplicationMain"]; // reserved for later use
    
    // I have some files that are purely generic type stuff and access checks kills 'em
    BOOL skipAccessCheckForFile = [string containsString:@"##SkipAccessChecksForFile"];
    if (skipAccessCheckForFile)
    {
        Log(@"Developer-directed file skip");
        return;
    }
    
    // Splinter into lines
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    
    int count = 0;
    int cautions = 0;
    int warnings = 0;
    
    // In shell build phases you can write to stderr using the following format:
    // <filename>:<linenumber>: error | warn | note : <message>\n
    
    for (NSString *eachLine in lines)
    {
        ++count;
        NSString *line = eachLine;
        
        // META PROCESSING
        // This material is always active and should never be overridden by command-line parameters
        {
            
#pragma mark - Keyword Processing

            // No worries, mate! Skip any line with nwm
            if ([RegexHelper testString:@"nwm" inString:line]) continue;
            
            // Convert all FIXMEs to warnings
            if ([RegexHelper testString:@"FIXME" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd is broken", path, count, count);
                Log(@"%@", line);
            }
            else if ([RegexHelper testString:@"TODO" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd needs addressing", path, count, count);
                Log(@"%@", line);
            }
            else if ([RegexHelper testString:@"HACK" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses inelegant problem solving", path, count, count);
                Log(@"%@", line);
            }
            else if ([RegexHelper testString:@"NOTE: " inString:line])
            {
                NSRange range = [line rangeOfString:@"NOTE: "]; // should always be found
                NSString *remaining = [line substringFromIndex:range.location];
                Log(@"%@:%zd: note: Line %zd : %@", path, count, count, remaining);
                Log(@"%@", line);
            }
            else if ([RegexHelper testString:@"WARNING: " inString:line])
            {
                NSRange range = [line rangeOfString:@"WARNING: "]; // should always be found
                NSString *remaining = [line substringFromIndex:range.location];
                Log(@"%@:%zd: warning: Line %zd : %@", path, count, count, remaining);
                Log(@"%@", line);
            }
            else if ([RegexHelper testString:@"ERROR: " inString:line])
            {
                NSRange range = [line rangeOfString:@"ERROR: "]; // should always be found
                NSString *remaining = [line substringFromIndex:range.location];
                Log(@"%@:%zd: error: Line %zd : %@", path, count, count, remaining);
                Log(@"%@", line);
                _encounteredErrors = YES;
            }

#pragma mark - Single-line Comment Processing
            
            // Avoid false pings on lines by clipping trailing comments
            NSRange range = [line rangeOfString:@"// "];
            if (range.location != NSNotFound)
            {
                line = [line substringToIndex:range.location];
                
                // Also trims start of line, but that shouldn't be an issue for the following checks
                line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            
            // Skip commented lines. This is not particularly reliable.
            if ([RegexHelper testPattern:@"^\\s*//" inString:line])
                continue;
        }
        
#pragma mark - STYLE ISSUES
        
        // STYLE ISSUES
        {
            
#pragma mark - Check for Colon style issues
            
            /*

             This is another one that goes against personal taste.
             I much prefer spaces before and after colons for the most part (except
             in parameter lists, where I left associate with the label) but again
             consistency and peer pressure wins.
             
             Reliability/Stability: Medium

             */
            // Spaces before colons
            if ([RegexHelper testPattern:@"\\?\\s+.*:" inString:line])
            {
                // ignore "? x : y" in ternary statements
            }
            else if ([RegexHelper testPattern:@"\\?\\s+:" inString:line])
            {
                // ignore "? :" in ternary statements
            }
            else if ([RegexHelper testPattern:@"\".*:.*\"" inString:line])
            {
                // ignore between quotes (will miss a bunch here)
            }
            else if ([RegexHelper testPattern:@"\\?\\s+:" inString:line])
            {
                // ignore "? :" in ternary statements
            }
            else if ([RegexHelper testPattern:@"\\s+\\:" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses a space before a colon", path, count, count);
            }
            
            // Spaces missing after colons
            if ([RegexHelper testPattern:@"http\\:\\S+" inString:line]) {
                // skip http:
            }
            else if ([RegexHelper testPattern:@"\"H\\:" inString:line] ||
                     [RegexHelper testPattern:@"\"V\\:" inString:line])
            {
                // skip for "H: and "V:
            }
            else if ([RegexHelper testPattern:@"[:]" inString:line])
            {
                // allow [:]
            }
            else if ([RegexHelper testPattern:@"\\:\\S+" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd lacks a space after a colon", path, count, count);
            }
            
#pragma mark - Kevin Tests
            
            /*
             
             The Rule of Kevin: “When a trailing closure argument is functional, 
             use parentheses. When it is procedural, use braces.”
             The consistency of style communicates whether closures return values. 
             There’s an ongoing dispute as to whether a space should be left before  
             trailing braces.
             
             Reliability/Stability: Quite Low
             
             */
            
            if ([RegexHelper testPattern:@"map\\s*\\{" inString:line] ||
                [RegexHelper testPattern:@"filter\\s*\\{" inString:line] ||
                [RegexHelper testPattern:@"flatMap\\s*\\{" inString:line] ||
                [RegexHelper testPattern:@"withCString\\s*\\{" inString:line] ||
                [RegexHelper testPattern:@"minElement\\s*\\{" inString:line] ||
                [RegexHelper testPattern:@"maxElement\\s*\\{" inString:line] ||
                [RegexHelper testPattern:@"sort\\s*\\{" inString:line] ||
                [RegexHelper testPattern:@"reduce\\s*\\{" inString:line]
                )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd fails the Rule of Kevin. Use parens around functional calls", path, count, count);
            }
            else if ([RegexHelper testPattern:@"sortInPlace\\s*\\({" inString:line] ||
                     [RegexHelper testPattern:@"startsWith\\s*\\({" inString:line] ||
                     [RegexHelper testPattern:@"elementsEqual\\s*\\({" inString:line] ||
                     [RegexHelper testPattern:@"contains\\s*\\({" inString:line] ||
                     [RegexHelper testPattern:@"element\\s*\\({" inString:line] ||
                     [RegexHelper testPattern:@"flatten\\s*\\({" inString:line] ||
                     [RegexHelper testPattern:@"forEach\\s*\\({" inString:line] ||
                     [RegexHelper testPattern:@"lexicographicalCompare\\s*\\({" inString:line]
                     )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd fails the Rule of Kevin. Skip parens around procedural calls", path, count, count);
            }
            
#pragma mark - Core Geometry tests
            
            /*
             
             Prefer modern constructors, accessors, constants to old-style ones
             
             Reliability/Stability: Medium
             
             */
            
            if ([RegexHelper testString:@"CGRectMake" inString:line] ||
                [RegexHelper testString:@"CGPointMake" inString:line] ||
                [RegexHelper testString:@"CGSizeMake" inString:line] ||
                [RegexHelper testString:@"CGVectorMake" inString:line]
                )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd: Prefer native constructors over old-style convenience functions", path, count, count);
            }
            else if ((![RegexHelper testString:@"CGAffineTransformMake" inString:line]) &&
                ([RegexHelper testPattern:@"CG[:word:]*Make" inString:line] ||
                 [RegexHelper testString:@"NSMake" inString:line]))
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd: Prefer native constructors over old-style convenience functions", path, count, count);
            }

            
            if ([RegexHelper testString:@"CGPointGetMinX" inString:line] ||
                [RegexHelper testString:@"CGPointGetMinY" inString:line] ||
                [RegexHelper testString:@"CGPointGetMidX" inString:line] ||
                [RegexHelper testString:@"CGPointGetMidY" inString:line] ||
                [RegexHelper testString:@"CGPointGetMaxX" inString:line] ||
                [RegexHelper testString:@"CGPointGetMaxY" inString:line]
                )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses non-Swift Core Geometry value accessors. Use .min, .mid, .max properties instead", path, count, count);
            }
            
            
            if ([RegexHelper testString:@"CGRectGetHeight" inString:line] ||
                [RegexHelper testString:@"CGRectGetWidth" inString:line]
                )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses non-Swift Core Geometry value accessors. Use .width, .height properties instead", path, count, count);
            }
            
            
            if ([RegexHelper testString:@"CGRectZero" inString:line] ||
                [RegexHelper testString:@"CGPointZero" inString:line] ||
                [RegexHelper testString:@"CGSizeZero" inString:line] ||
                [RegexHelper testString:@"CGRectInfinite" inString:line] ||
                [RegexHelper testString:@"CGRectNull" inString:line]
                )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses non-Swift Core Geometry constants. Use .zero, .infinite, .null static properties instead", path, count, count);
            }
            
            if ([RegexHelper testString:@"CGRectMinXEdge" inString:line] ||
                [RegexHelper testString:@"CGRectMinYEdge" inString:line] ||
                [RegexHelper testString:@"CGRectMaxXEdge" inString:line] ||
                [RegexHelper testString:@"CGRectMaxYEdge" inString:line]
                )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses non-Swift Core Geometry edge types. Use min(XY)/mid(XY)/max(XY) properties instead", path, count, count);
            }
            
            if ([RegexHelper testString:@"CGFLOAT_MIN" inString:line] ||
                [RegexHelper testString:@"CGFLOAT_MAX" inString:line]
                )
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses non-Swift Core Geometry constants. Use CGFloat.min and CGFloat.max instead", path, count, count);
            }

            
#pragma mark - Use of yorn (always bad, not swift specific)
            /*

             yorn is a bad habit I need to break.
             Reliability/Stability: High
             
             */
            
            if ([RegexHelper testString:@"yorn" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses yorn. yorn is wrong. Prefer parameter-specific boolean names over yes-or-no", path, count, count);
            }
            
#pragma mark - Single-line Brace Check

            /*

             Reliability/Stability: High but I'm not sure I really care about this test
             
             */
            
            {
                if ([RegexHelper testPattern:@"\\{.*;.*\\}" inString:line])
                {
                    ++warnings;
                    Log(@"%@:%zd: warning: Line %zd Excessive content in single-line scope", path, count, count);
                }
                
                /*

                 Excessive single-line brace length
                 I've disabled this for now, but I'm wavering back and forth on its value.
                 This would apply a maximum size check instead of existence check

                 */

                //        if ([RegexHelper testPattern:@"\\{.{80,}\\}" inString:line])
                //        {
                //            ++warnings;
                //            Log(@"%@:%zd: Line %zd warning: Excessive content in single-line scope", path, count, count);
                //        }
            }
            
#pragma mark - Allman Check
            
            /*

             True fact. I love 💗💗 Allman. It's the best for teaching and reading, not to mention the
             better cognitive load for general dev. However, I'm operating under external pressures.
             I have caved here.
             
             Reliability/Stability: High, but :(

             */
            
            // Allman
            if ([RegexHelper testPattern:@"^\\s*\\{" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd uses egregious Allman pattern. Welcome to Swift.", path, count, count);
            }
            
            if (![RegexHelper testString:@"#else" inString:line] &&
                ([RegexHelper testPattern:@"^\\s*else" inString:line] ||
                 [RegexHelper testPattern:@"else\\s*$" inString:line]))
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd Else case does not follow colinear 1TBS standard.", path, count, count);
            }
            
//            // This is the anti-Allman version. I don't know why I have it here.
//            if ([RegexHelper testPattern:@"\\S+\\s*\\{" inString:line])
//            {
//                ++warnings;
//                Log(@"%@:%zd: warning: Line %zd uses non-Allman pattern. Kittens cry.", path, count, count);
//            }
//            
//            if ([RegexHelper testPattern:@"\\}\\s+else" inString:line] ||
//                [RegexHelper testPattern:@"else\\s+{" inString:line])
//            {
//                ++warnings;
//                Log(@"%@:%zd: warning: Line %zd Else case does not follow Allman standard.", path, count, count);
//            }
            
#pragma mark - Use of temp, tmp
            /*
             
             Avoid meaningless names
             stability/reliability: high
             exhaustive definition: low
             
             */
            if ([RegexHelper testString:@"temp" inString:line] ||
                [RegexHelper testString:@"tmp" inString:line] ||
                [RegexHelper testString:@"results" inString:line] ||
                [RegexHelper testString:@"returnValue" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd: Avoid semantically meaningless names like temp, tmp, returnValue", path, count, count);
            }
            
            /*
             
             Prefer meaningful index names
             stability/reliability: medium-ish
             Maybe replace with for var rule (prefer in over C-style loops)
             or forEach.
             
             */
            if ([RegexHelper testPattern:@"var i[\\s=]" inString:line] ||
                [RegexHelper testPattern:@"var j[\\s=]" inString:line] ||
                [RegexHelper testPattern:@"for.*\\s+i\\s+in" inString:line])
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd: Avoid semantically meaningless iterator names (i, j)", path, count, count);
            }
        }
        
        // FILE HYGIENE
        
#pragma mark - Trailing Whitespace
        /*

         Trailing whitespace
         Reliability/Stability: Very high
         
         */

        // Trailing whitespace on lines
        if ([RegexHelper testPattern:@"\\s+//.*\\S\\s+$" inString:line])
        {
            // ignore extra spaces on comment lines
        }
        else if ([RegexHelper testPattern:@"\\S\\s+$" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd includes trailing whitespace characters", path, count, count);
        }

#pragma mark - LANGUAGE ISSUES
        
#pragma mark - Collection Constructor Checks
        /*
         
         Collection Constructors
         Reliability/Stability: Medium-High
         
         */
        
        if ([RegexHelper testPattern:@"=.*>\\(\\)" inString:line]||
            [RegexHelper testPattern:@"=.*]\\(\\)" inString:line]
            ) {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: avoid type-based constructors and prefer [] or [:] initialization instead", path, count, count);
        }


        
        // LANGUAGE ISSUES
        /*
         
         This is terrible with embedded functions (no access modifiers) and properties but it will generally start highlighting
         files that you haven't done a full access modifier audit on, so you know which items to buckle down on and fix. 
         Wouldn't it be great if Swift did this bit for you, basically when you say: "Make everything in this construct
         public that can be public" and then you can tweak down what you want to be internal and private.
         
         There are some implementation details such as no public modifiers for many generic details, so be aware of this going in.
         
         */
        
        
#pragma mark - Space check after init
        /*
         
         init checks - skip space between init or init? and (
         stability/reliability: High
         
         */
        if ([RegexHelper testPattern:@"init\\?*\\s+\\(" inString:line]){
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Extraneous space in init( or init?( declaration", path, count, count);
        }
        
#pragma mark - Prefer for-in or forEach over C-style loops
        /*

         Mostly avoid "for var" in favor of for name in
         stability/reliability: med
         Not sure this is a great rule or not
         
         */
        if ([RegexHelper testString:@"for var" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Prefer for-in or forEach over C-style loops", path, count, count);
        }

#pragma mark - (...) -> Void check
        
        /*
         
         Void return type check
         stability/reliability high
         
         */
        
        // Check that -> return tokens point to Void and not () and that they are surrounded by spaces
        if ([RegexHelper testString:@"->=" inString:line]) {
            // Skip ->=
        } else if ([RegexHelper testPattern:@"->\\s*\\(\\)" inString:line]) {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Prefer Void as a return type over ()", path, count, count);
        } else if ([RegexHelper testPattern:@"->\\S" inString:line] ||
                   [RegexHelper testPattern:@"\\S->" inString:line]) {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: leave spaces around the -> return token", path, count, count);
        }
        
#pragma mark - Terminal semicolons
        
        /*
         
         Terminal semicolons check
         stability/reliability high
         
         */

        
        // Eliminate line-terminating semicolons
        if ([RegexHelper testPattern:@";\\s*$" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Swift does not require terminal semicolons except for statement separation. They are bad. You should feel bad.", path, count, count);
        }
        
#pragma mark - Check for parens around if conditions
        
        /*
         
         Eliminate parentheses around if conditions
         stability/reliability medium
         can fail with if (x == y) && (z == w) for example
         
         */

        if ([RegexHelper testPattern:@"if[\\s]*\\(" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Swift if statements do not require parentheses", path, count, count);
        }
        
#pragma mark - Check for parens around switch conditions
        
        /*
         
         Eliminate parentheses around switch conditions that aren't tuples
         stability/reliability medium
         
         */
        if ([RegexHelper testPattern:@"switch\\s*\\(.*,.*\\)\\s*\\{" inString:line])
        {
            // skip likely tuples
        }
        else if ([RegexHelper testPattern:@"switch\\s*\\(" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Swift switch statements do not require parentheses", path, count, count);
        }
        
#pragma mark - Check for Pattern Matching issues
        /*
         
         Just starting on this, which is for testing for less
         desirable pattern matching habits.
         
         Reliability/Stability: Quite Low
         
         */
        
        if ([RegexHelper testPattern:@"case\\s*\\(let" inString:line] ||
            [RegexHelper testPattern:@"case\\s*\\(var" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd embeds let/var. Consider moving the binding keyword outs of the parens", path, count, count);
        }

#pragma mark - Extraneous lets
        
        /*
         
         Extraneous lets. For multi-line in-context scan, would test for ,\s*\n\s*let
         stability/reliability medium
         
         */
        
        if ([RegexHelper testString:@"case" inString:line])
        {
            // do not test with case statements
        }
        else if ([RegexHelper testString:@"(.*let" inString:line])
        {
            // Skip lines that are likely tuple assignments in switch statements
        }
        else if ([RegexHelper testString:@", let" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Check for extraneous let usage in cascaded let", path, count, count);
        }
        
#pragma mark - Forced unwraps and casts
        /*
         
         Forced unwraps and casts
         Limit use of forced unwrap and casts, however there are some cromulent reasons to
         use these. Currently issued as warning rather than caution, but may downgrade or
         offer forceChecksAreCautions option.

         stability/reliability medium
         
         */
        if ([RegexHelper testString:@" as!" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Forced casts are generally unsafe", path, count, count);
        }
        else if ([RegexHelper testPattern:@":\\s*\\w+! " inString:line])
        {
            // Also a do-nothing. This is likely an implicitly unwrapped declaration
        }
        else if ([RegexHelper testString:@"! " inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Forced unwrapping is unsafe. Use let to conditionally unwrap where possible.", path, count, count);
        }
        
#pragma mark - Extraneous break statements
        
        /*
         
         Eliminate extraneous breaks in switch patterns other than in default statements
         For multi-line in-context, should test for control-flow use of break
         
         stability/reliability medium
         
         */
        
        if ([RegexHelper testPattern:@":\\s+break" inString:line])
        {
            // skip "case ...: break" cases
        }
        else if ([RegexHelper testString:@"{" inString:line] ||
                 [RegexHelper testString:@"}" inString:line])
        {
            // whitelist any break on a line with } or {
        }
        else if ((lines.count > (count + 1)) &&
                 [RegexHelper testString:@"}" inString:lines[count + 1]])
        {
            // whitelist any break is followed by a line with a }
        }
        else if ([RegexHelper testString:@"break" inString:line])
        {
            // was the previous line "default"?
            // this line is count - 1. previous line is count - 2
            if ((count - 2) > 0)
            {
                NSString *previousLine = lines[count - 2];
                if (![RegexHelper testString:@"default:" inString:previousLine])
                {
                    ++warnings;
                    Log(@"%@:%zd: warning: Line %zd: Swift cases do not implicitly fall through.", path, count, count);
                }
            }
        }
        
#pragma mark - Empty count checks
        
        /*
         
         Test for .count == 0 and count() == 0 that might be better as isEmpty
         Should this be a warning or a caution? May also catch mirror.count
         
         stability/reliability medium to high
         
         */
        
        if ([RegexHelper testPattern:@"mirror" inString:line])
        {
            // Ignore any line that references mirrors.
        }
        else if ([RegexHelper testPattern:@"\\.count\\s*==\\s*0" inString:line] ||
                 [RegexHelper testPattern:@"count\\(.*\\)\\s*==\\s*0" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Consider replacing zero count check with isEmpty.", path, count, count);
        }
        
#pragma mark - NSNotFound checks
        
        /*
         
         Test for any use of NSNotFound, use contains instead?
         
         stability/reliability high
         
         */
        
        if ([RegexHelper testPattern:@"!=\\s*NSNotFound" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Consider replacing NSNotFound pattern with contains", path, count, count);
        }
        
#pragma mark - Ref checks
        
        /*
         
         Try to find CG/CF constructors with Ref at the end
         
         stability/reliability medium
         
         */
        
        if ([RegexHelper testCaseSensitivePattern:@"[:upper:]{3}\\w*Ref\\W" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd CFReference types need not end with Ref in Swift", path, count, count);
        }

#pragma mark - Trailing Closures
        /*
         
         Goal: Use trailing closures only for procedural elements that do not pass through values
         
         NOT: withUnsafeBufferPointer, withUnsafeMutableBufferPointer, withUTF8Buffer, withCString,
         withExtendedLifetime, withUnsafePointer, withUnsafePointers, withUnsafeMutablePointer, withUnsafeMutablePointers,
         withVaList
         
         stability/reliability medium, especially as language constructs evolve
         
         s: `@"\b(map|flatMap|filter|indexOf|minElement|...)\s*{"`
         
         */
        
        if ([RegexHelper testPattern:@"map\\s*{" inString:line] ||
            [RegexHelper testPattern:@"flatMap\\s*{" inString:line] ||
            [RegexHelper testPattern:@"filter\\s*{" inString:line] ||
            [RegexHelper testPattern:@"indexOf\\s*{" inString:line] ||
            [RegexHelper testPattern:@"minElement\\s*{" inString:line] ||
            [RegexHelper testPattern:@"maxElement\\s*{" inString:line] ||
            [RegexHelper testPattern:@"startsWith\\s*{" inString:line] ||
            [RegexHelper testPattern:@"elementsEqual\\s*{" inString:line] ||
            [RegexHelper testPattern:@"lexicographicalCompare\\s*{" inString:line] ||
            [RegexHelper testPattern:@"contains\\s*{" inString:line] ||
            [RegexHelper testPattern:@"reduce\\s*{" inString:line] ||
            [RegexHelper testPattern:@"startsWith\\s*{" inString:line] ||
            [RegexHelper testPattern:@"split\\s*{" inString:line]
            )
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd Treat non-procedural trailing closures as arguments by enclosing within parens", path, count, count);
        }

#pragma mark - MAX and MIN usage
        /*
         
         Any use of _MAX / MIN or some name like that is likely to be replaced in Swift by .max/.min
         
         */
        
        if ([RegexHelper testString:@"_MAX" inString:line] ||
            [RegexHelper testString:@"_MIN" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd Prefer Swift .max and .min over old constants", path, count, count);
        }
        

        
#pragma mark - Antiquated -> ( tests
        /*
         
         Check for -> ( patterns
         
         stability/reliability medium 
         
         */
        
        if ([RegexHelper testPattern:@"->\\s*\\([^,]*\\)" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd parens after return token are not required except for tuples", path, count, count);
        }
        

#pragma mark - Option Set checks
        /*
         
         Convert option sets with raw values to []
         
         stability/reliability low-medium (will improve as I figure this out)
         
         */
        if ([RegexHelper testString:@"Options" inString:line] &&
            [RegexHelper testPattern:@"rawValue:\\s*0\\)" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd Many zero options can now be replaced with [] instead", path, count, count);
        }
        else if ([RegexHelper testPattern:@"rawValue:" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd Many rawValue initializers can now be replaced with option set initialization", path, count, count);
        }
        
        
#pragma mark - Enumeration prefix checks
        
        /*
         
         Highlight enumeration prefixes for elimnation
         
         stability/reliability high
         note the list needs to be upgraded for iOS 9/OS X 10.11
         
         */

        for (NSString *prefix in prefixes)
        {
            // Has enumeration prefix with dot after but no rawValue
            if ([line rangeOfString:[prefix stringByAppendingString:@"."]].location != NSNotFound &&
                [line rangeOfString:@"rawValue"].location == NSNotFound)
            {
                ++warnings;
                Log(@"%@:%zd: warning: Line %zd: Swift type inference may not require enumeration prefix on this line", path, count, count);
            }
        }
        
#pragma mark - Constructor checks
        
        /*
         
         Find constructors, which in context may use inferrable class types
         
         stability/reliability low - medium
         
         */

        {
            // Matches most no-arg class methods as likely constructors
            if ([RegexHelper testCaseSensitivePattern:@"^\\s*[:upper:]\\w+\\.\\w+\\(\\)" inString:line])
            {
                // first thing on line? skip.
            }
            else if ([RegexHelper testCaseSensitivePattern:@"let\\s*\\w+\\s*[=]\\s*[:upper:]\\w+\\.\\w+\\(\\)" inString:line] ||
                     [RegexHelper testCaseSensitivePattern:@"var\\s*\\w+\\s*[=]\\s*[:upper:]\\w+\\.\\w+\\(\\)" inString:line])
            {
                // after let or var assignment, skip. There won't be any context for type inference
            }
            else if ([RegexHelper testCaseSensitivePattern:@"[=]\\s*[:upper:]\\w+\\.\\w+\\(\\)" inString:line])
            {
                // after assignment, e.g. view.backgroundColor = UIColor.blueColor()
                ++cautions;
                Log(@"%@:%zd: note: Line %zd: CAUTION: Possible constructor assignment pattern may not require inferred prefix", path, count, count);
                Log(@"%@", line);
            }
            else if ([RegexHelper testCaseSensitivePattern:@"[ :,\{\(][:upper:]\\w+\\.\\w+\\(\\)" inString:line])
            {
                ++cautions;
                Log(@"%@:%zd: note: Line %zd: CAUTION: Possible constructor pattern may not require inferred prefix", path, count, count);
                Log(@"%@", line);
            }
        }
        
#pragma mark - Self. reference checks
        
        /*
         
         self references that may not be needed
         stability/reliability medium - high
         
         */
        
        if ([RegexHelper testString:@"self.init" inString:line])
        {
            // Skip self.init pattern
        }
        else if ([RegexHelper testPattern:@"self\\.(\\w+)\\s*=\\s*\\1" inString:line])
        {
            // Skip likely self-initialization self.x = x
        }
        else if ([RegexHelper testPattern:@"\\\\\\(self" inString:line])
        {
            // Skip likely in-string reference \(self
        }
        else if ([RegexHelper testPattern:@"\\{.*self" inString:line])
        {
            // Skip single line likely closure reference {....self...}
        }
        else if ([RegexHelper testString:@"self[" inString:line])
        {
            // Skip array access
        }
        else if ([RegexHelper testPattern:@"self\\.(\\S)+\\s*=\\s*\\S" inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Swift does not usually require 'self' references for assignments", path, count, count);
        }
        else if ([RegexHelper testString:@"self." inString:line])
        {
            ++warnings;
            Log(@"%@:%zd: warning: Line %zd: Swift does not usually require 'self' references outside of closures", path, count, count);
        }
    }

#pragma mark - FILE ISSUES
    
#pragma mark - File ending check
    
    /*
     
     Check for trailing or missing newlines
     stability/reliability high
     
     */

    // File-level line hygiene
    if ([string hasSuffix:@"\n\n"] || ![string hasSuffix:@"\n"])
    {
        ++warnings;
        Log(@"%@:0: warning: File %@ should have a single trailing newline", path, path.lastPathComponent);
    }

    Log(@"%zd warnings, %zd cautions for %@", warnings, cautions, path.lastPathComponent);
}
@end

