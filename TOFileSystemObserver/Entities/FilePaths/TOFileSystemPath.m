//
//  TOFileSystemPath.m
//
//  Copyright 2019-2020 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

+ (NSDictionary<NSURL *, NSArray *> *)directoryDictionaryWithItemURLs:(NSArray<NSURL *> *)itemURLs
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    return dictionary;
}

@end
