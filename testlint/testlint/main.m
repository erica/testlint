/*
 
 Erica Sadun, http://ericasadun.com
 
 */

#import <Foundation/Foundation.h>
#import "Linter.h"
#import "Utility.h"
#import "NSArray+Frankenstein.h"

@interface Processor : NSObject
@property (nonatomic, strong) Linter *linter;
@end

@implementation Processor

#pragma mark - Linter

- (Linter *) linter
{
    if (!_linter) _linter = [Linter new];
    return _linter;
}

- (instancetype) init
{
    if (!(self = [super init])) return self;
    return self;
}

- (void) dealloc
{
}


#pragma mark - Paths

- (NSString *) projectName
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *wd = manager.currentDirectoryPath;
    NSArray *contents = [manager contentsOfDirectoryAtPath:wd error:nil];
    NSArray *filtered = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self endswith 'xcodeproj'"]];
    if (!filtered.count) return nil;
    return [filtered.lastObject stringByDeletingPathExtension];
}

- (NSString *) projectPath
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *wd = manager.currentDirectoryPath;
    NSArray *contents = [manager contentsOfDirectoryAtPath:wd error:nil];
    NSArray *filtered = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self endswith 'xcodeproj'"]];
    if (!filtered.count) return nil;
    return [wd stringByAppendingPathComponent:filtered.lastObject];
}

- (NSArray *) fetchPathsForDict: (NSDictionary *) dict
{
    NSMutableArray *results = @[].mutableCopy;
    NSMutableDictionary *objects = [dict[@"objects"] mutableCopy];
    
    NSArray *groups = [objects.allKeys collect:^BOOL(id object) {
        NSDictionary *d = objects[object];
        BOOL group = [d[@"isa"] isEqualToString:@"PBXGroup"];
        return group;
    }];
    
    NSMutableArray *files = [objects.allKeys collect:^BOOL(id object) {
        NSDictionary *d = objects[object];
        BOOL isSwift = [d[@"lastKnownFileType"] isEqualToString:@"sourcecode.swift"];
        return isSwift;
    }].mutableCopy;
    
    for (NSString *key in groups)
    {
        NSDictionary *group = objects[key];
        NSString *groupPath = group[@"path"];
        
        for (NSString *childKey in group[@"children"])
        {
            NSDictionary *child = objects[childKey];
            [files removeObject:childKey];
            BOOL isSwiftFile = [child[@"lastKnownFileType"] isEqualToString:@"sourcecode.swift"];
            if (!isSwiftFile) continue;

            NSString *childPath = child[@"path"];
            if (!childPath) continue;

            NSString *wd = [[NSFileManager defaultManager] currentDirectoryPath];
            if (!groupPath) groupPath = [wd stringByAppendingPathComponent:[self projectName]];
            NSString *path = [groupPath stringByAppendingPathComponent:childPath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [results addObject:path];
                continue;
            }

            const char *cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
            char *resolved = NULL;
            char *returnValue = realpath(cpath, resolved);
            if (returnValue == NULL || resolved == NULL) continue;
            [results addObject:[NSString stringWithCString:returnValue encoding:NSUTF8StringEncoding]];
        }
    }
    
    // Files not in groups
    for (NSString *fileKey in files)
    {
        NSDictionary *dict = objects[fileKey];
        NSString *path = dict[@"path"];
        NSLog(@"NOTGROUP: %@", dict);
        const char *cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
        char *resolved = NULL;
        char *returnValue = realpath(cpath, resolved);
        NSLog(@"path: %@, cpath: %s, resolved %s return value %s", path, cpath, resolved, returnValue);
        if (returnValue == NULL || resolved == NULL) continue;
        [results addObject:[NSString stringWithCString:returnValue encoding:NSUTF8StringEncoding]];
    }
    
    return results;
}

#pragma mark - Action

- (void) processIndividualItems: (NSArray *) args
{
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *arg in args) {
        
        // Establish path
        BOOL isDir = false; NSString *path = arg;
        if ([arg isEqualToString:@"."]) path = manager.currentDirectoryPath;
        if (![manager fileExistsAtPath:path isDirectory:&isDir])
            path = [manager.currentDirectoryPath stringByAppendingPathComponent:arg];
        if (![manager fileExistsAtPath:path isDirectory:&isDir]) continue;
        
        // Process each Swift file
        if ([path hasSuffix:@".swift"])
        {
            Log(@"Checking '%@'", path.lastPathComponent);
            [self.linter lint:path];
            continue;
        }
        
        // Recursively descend through directories
        if (isDir)
        {
            NSMutableArray *files = @[].mutableCopy;
            for (NSString *file in [manager contentsOfDirectoryAtPath:path error:nil])
                [files addObject:[arg stringByAppendingPathComponent:file]];
            [self processIndividualItems:files];
            continue;
        }
    }
}

// Entry point for project builds
- (void) go: (NSArray *) args
{
    if (args.count > 0)
    {
        [self processIndividualItems:args];
        return;
    }
    
    // Find embedded project.pbxproj
    NSString *xcpath = [self projectPath]; if (!xcpath) return;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:[NSURL fileURLWithPath:xcpath] options:NSFileWrapperReadingImmediate error:nil];
    if (!fileWrapper.isDirectory) return;
    NSFileWrapper *pbx = fileWrapper.fileWrappers[@"project.pbxproj"]; if (!pbx) return;
    
    // Read XML
    CFDataRef xmlData = (__bridge CFDataRef)pbx.regularFileContents;
    CFPropertyListFormat format = kCFPropertyListXMLFormat_v1_0;
    CFPropertyListRef plist = CFPropertyListCreateWithData(kCFAllocatorDefault, xmlData, kCFPropertyListMutableContainers, &format, nil);
    if (!plist) return;
    
    // Fetch project file paths
    NSDictionary *dict = (__bridge_transfer NSDictionary *) plist;
    NSArray *paths = [self fetchPathsForDict:dict];
    int count = 0;
    for (NSString *path in paths)
    {
        Log(@"Checking '%@' (%zd of %zd):", path.lastPathComponent, ++count, paths.count);
        [self.linter lint:path];
    }
}
@end

#pragma mark - Usage

// accessModifierChecks
void usage(NSString *appname)
{
    Log(@"Usage: %@ options file...", appname);
    Log(@"    help:                       -help");
    Log(@"");
    Log(@"Use 'NOTE: ', 'ERROR: ', 'WARNING: ', HACK, and FIXME to force emit");
    Log(@"Use 'nwm' to skip individual line processing: // nwm");
    Log(@"Use ##SkipAccessChecksForFile somewhere to skip file processing");
    exit(-1);
}

#pragma mark - Command-line entry point

#define DEFAULT_OBJ(_KEY_)      [[NSUserDefaults standardUserDefaults] objectForKey:_KEY_]
typedef void (^UtilityBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Processor *processor = [Processor new];
        
        // Fetch app name and arguments
        NSString *appName = [[NSProcessInfo processInfo] arguments].firstObject;
        NSMutableArray *arguments = [[NSProcessInfo processInfo] arguments].mutableCopy;
        [arguments removeObjectAtIndex:0]; // remove app name
        
        // Fetched dashed arguments
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF beginswith '-'"];
        NSArray *dashedArguments = [arguments filteredArrayUsingPredicate:predicate];
        
        // Equivalence list for argument conversion to standard form
        NSDictionary *equivalences = @{
                                       @"--help" : @"-help",
                                       @"--h" : @"-help",
                                       @"-h" : @"-help",
                                       };
        
        // Should continue execution after processing arguments
        BOOL __block shouldContinue = YES;
        
        for (NSString *actualArgument in dashedArguments)
        {
            NSString *argument = actualArgument;
            [arguments removeObject:argument]; // trim down to just items listed at end

            if (equivalences[actualArgument]) argument = equivalences[actualArgument];
            //  NSString *argumentValue = DEFAULT_OBJ([actualArgument substringFromIndex:1]);
            
            UtilityBlock block = @{
                                   @"-help" : ^{
                                       // Quits after help
                                       usage(appName);
                                   },
                                   }[argument];
            if (block) block();
        }
        if (!shouldContinue) exit(0);
        [processor go:arguments];
        return processor.linter.encounteredErrors ? -1 : 0;
    }
    return 0;
}
