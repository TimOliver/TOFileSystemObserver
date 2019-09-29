//
//  TOFileSystemPath.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemPath.h"

@implementation TOFileSystemPath

+ (NSURL *)applicationSandboxURL
{
    return [NSURL fileURLWithPath:NSHomeDirectory()];
}

+ (NSURL *)documentsDirectoryURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
}

+ (NSURL *)cachesDirectoryURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].lastObject;
}

+ (NSString *)defaultDatabaseFileName
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    return [NSString stringWithFormat:@"%@.fileSystemSnapshots.realm", bundleIdentifier];
}

+ (NSString *)relativePathWithPath:(NSURL *)fileURL
{
    NSString *sandboxPath = [TOFileSystemPath applicationSandboxURL].path;
    NSString *path = fileURL.path;

    // Replace the sandbox portion with an empty string.
    path = [path stringByReplacingOccurrencesOfString:sandboxPath withString:@""];

    // Remove leading slashes
    if ([[path substringToIndex:1] isEqualToString:@"/"]) {
        path = [path substringFromIndex:1];
    }

    // Remove trailing slashes
    if ([[path substringFromIndex:path.length - 1] isEqualToString:@"/"]) {
        path = [path substringToIndex:path.length - 2];
    }

    return path;
}

@end
