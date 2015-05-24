/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import "Utility.h"

void Log(NSString *formatString,...)
{
    va_list arglist;
    if (formatString)
    {
        va_start(arglist, formatString);
        NSString *outstring = [[NSString alloc] initWithFormat:formatString arguments:arglist];
        fprintf(stderr, "%s\n", [outstring UTF8String]);
        va_end(arglist);
    }
}
