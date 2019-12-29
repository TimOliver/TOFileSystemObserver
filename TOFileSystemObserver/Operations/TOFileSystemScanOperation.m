//
//  TOFileSystemScanOperation.m
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
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

#import "TOFileSystemScanOperation.h"
#import "TOFileSystemItem.h"
#import "TOFileSystemPresenter.h"

#import "NSURL+TOFileSystemUUID.h"
#import "NSURL+TOFileSystemStandardized.h"
#import "NSFileManager+TOFileSystemDirectoryEnumerator.h"

@interface TOFileSystemScanOperation ()

/** When scanning folder hierarchy, this is the top level directory */
@property (nonatomic, strong) NSURL *directoryURL;

/** A flat list of file URLs to scan. */
@property (nonatomic, strong) NSArray *itemURLs;

/** A reference to the file system presenter object so we may pause when causing file writes. */
@property (nonatomic, strong) TOFileSystemPresenter *filePresenter;

/** A local file manager object we can use for retrieving disk contents. */
@property (nonatomic, strong) NSFileManager *fileManager;

/** When iterating through all the files, this array stores pending directories that need scanning*/
@property (nonatomic, strong) NSMutableArray *pendingDirectories;

@end

@implementation TOFileSystemScanOperation

#pragma - Class Lifecycle -

- (instancetype)initWithDirectoryAtURL:(NSURL *)directoryURL
                         filePresenter:(nonnull TOFileSystemPresenter *)filePresenter
{
    if (self = [super init]) {
        _directoryURL = directoryURL;
        _filePresenter = filePresenter;
        _pendingDirectories = [NSMutableArray array];
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithItemURLs:(NSArray<NSURL *> *)itemURLs
                   filePresenter:(TOFileSystemPresenter *)filePresenter
{
    if (self = [super init]) {
        _filePresenter = filePresenter;
        _itemURLs = itemURLs;
        [self commonInit];
    }

    return self;
}

- (void)commonInit
{
    _subDirectoryLevelLimit = -1;
    _fileManager = [[NSFileManager alloc] init];
}

#pragma mark - Scanning Implementation -

- (void)main
{
    // Terminate out if this operation was cancelled before it started
    // Once it's started however, we need to see it through to completion
    // to prevent leaving things in an inconsistent state.
    if (self.isCancelled) { return; }

    // Depending on if a base directory,
    // or a flat list of files was provided, perform
    // different scan patterns
    if (self.directoryURL) {
        [self scanAllSubdirectoriesFromBaseURL];
    }
    else if (self.itemURLs) {
        [self scanItemURLsList];
    }
}

#pragma mark - Deep Hierarcy Directory Scan -

- (void)scanAllSubdirectoriesFromBaseURL
{
    // Start scanning every item in our base directory
    NSArray *childItemURLs = [self.fileManager to_fileSystemEnumeratorForDirectoryAtURL:self.directoryURL].allObjects;
    if (childItemURLs.count == 0) { return; }

    // Scan all of the items in the base directory
    for (NSURL *url in childItemURLs) {
        [self scanItemAtURL:url.to_standardizedURL
         pendingDirectories:self.pendingDirectories];
    }

    // If we were only scanning the immediate contents
    // of the base directory, we can exit here
    if (self.subDirectoryLevelLimit == 0) { return; }

    // Otherwise, scan all of the directories discovered in the base
    // directory (and then scan their directories).
    [self scanPendingSubdirectories];
}

- (void)scanPendingSubdirectories
{
    NSMutableArray *pendingDirectories = self.pendingDirectories;

    // If there were any directories in the base, start a flat loop to scan
    // all subdirectories too (Avoiding potential stack overflows!)
    while (pendingDirectories.count > 0) {
        // Extract the item, and then remove it from the pending list
        NSURL *url = pendingDirectories.firstObject;
        [pendingDirectories removeObjectAtIndex:0];

        // Exit out if we've gone deeper than the specified limit
        if (self.subDirectoryLevelLimit > 0) {
            NSInteger levels = [self numberOfDirectoryLevelsToURL:url];
            if (levels > self.subDirectoryLevelLimit) { continue; }
        }

        // Create a new enumerator for it
        NSDirectoryEnumerator *enumerator = [self.fileManager to_fileSystemEnumeratorForDirectoryAtURL:url];
        for (NSURL *url in enumerator) {
            [self scanItemAtURL:url pendingDirectories:pendingDirectories];
        }
    }
}

#pragma mark - Flat File List Scan -

- (void)scanItemURLsList
{

}

#pragma mark - Shared Scanning Logic -

- (void)scanItemAtURL:(NSURL *)url pendingDirectories:(NSMutableArray *)pendingDirectories
{
    // Check if we've already assigned an on-disk UUID
    NSString *uuid = [url to_fileSystemUUID];

    NSNumber *isDirectory;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    
    // If the item is a directory
    if (isDirectory.boolValue) {
        // Add it to the pending list so we can start scanning it after this
        [pendingDirectories addObject:url];
    }
}

- (TOFileSystemItem *)itemForParentOfItemAtURL:(NSURL *)url
{
    return nil;
}

- (NSInteger)numberOfDirectoryLevelsToURL:(NSURL *)url
{
    NSInteger levels = 0;

    // Loop up from the URL to the base
    // directory to see how many levels deep it is.
    while (1) {
        url = [url URLByDeletingLastPathComponent];
        if ([url.lastPathComponent isEqualToString:@".."]) { break; } // To prevent infinite loops
        if ([url isEqual:self.directoryURL]) { break; }
        levels++;
    }

    return MAX(levels, -1);
}

@end
