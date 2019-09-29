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

@end
