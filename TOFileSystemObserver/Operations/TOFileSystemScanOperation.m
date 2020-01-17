//
//  TOFileSystemScanOperation.m
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

#import "TOFileSystemScanOperation.h"
#import "TOFileSystemPresenter.h"
#import "TOFileSystemItemURLDictionary.h"

#import "NSURL+TOFileSystemUUID.h"
#import "NSURL+TOFileSystemAttributes.h"
#import "NSFileManager+TOFileSystemDirectoryEnumerator.h"

/** In iOS, files deleted via the Files app are moved to this private folder. */
NSString * const kTOFileSystemTrashFolderName = @"/.Trash/";

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

/** A reference to the master list of items maintained by this observer. */
@property (nonatomic, strong) TOFileSystemItemURLDictionary *allItems;

/** A store for items that have disappeared inside this operation, either deleted or moved. */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURL *> *missingItems;

@end

@implementation TOFileSystemScanOperation

#pragma - Class Lifecycle -

- (instancetype)initWithDirectoryAtURL:(NSURL *)directoryURL
                    allItemsDictionary:(nonnull TOFileSystemItemURLDictionary *)allItems
                         filePresenter:(nonnull TOFileSystemPresenter *)filePresenter
{
    if (self = [super init]) {
        _directoryURL = directoryURL;
        _filePresenter = filePresenter;
        _allItems = allItems;
        _pendingDirectories = [NSMutableArray array];
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithItemURLs:(NSArray<NSURL *> *)itemURLs
              allItemsDictionary:(nonnull TOFileSystemItemURLDictionary *)allItems
                   filePresenter:(nonnull TOFileSystemPresenter *)filePresenter
{
    if (self = [super init]) {
        _filePresenter = filePresenter;
        _itemURLs = itemURLs;
        _allItems = allItems;
        _pendingDirectories = [NSMutableArray array];
        _missingItems = [NSMutableDictionary dictionary];
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
        [self scanItemAtURL:url.URLByStandardizingPath
         pendingDirectories:self.pendingDirectories];
    }

    void (^didCompletedNotification)(void) = ^{
        [self.delegate scanOperationDidCompleteFullScan:self];
    };
    
    // If we were only scanning the immediate contents
    // of the base directory, we can exit here
    if (self.subDirectoryLevelLimit == 0) {
        didCompletedNotification();
        return;
    }

    // Otherwise, scan all of the directories discovered in the base
    // directory (and then scan their directories).
    [self scanPendingSubdirectories];
    
    // Send a notification so we can do some final clean up
    didCompletedNotification();
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
    // Loop through each reported file URL and perform a scan to see what changed
    for (NSURL *itemURL in self.itemURLs) {
        [self scanItemAtURL:itemURL pendingDirectories:self.pendingDirectories];
    }
    
    // After all files are scanned, clean out any files
    [self cleanUpFilesPendingDeletion];
}

#pragma mark - Scanning Logic -

- (void)scanItemAtURL:(NSURL *)url pendingDirectories:(NSMutableArray *)pendingDirectories
{
    // Make sure it's not a hidden file
    NSString *name = url.lastPathComponent;
    if ([name characterAtIndex:0] == '.') { return; }
    
    // Double-check the file is still at that URL
    // (The file presenter will sometimes provide the old URL for moved files)
    if (![self verifyItemIsNotMissingAtURL:url]) {
        return;
    }
    
    // Check if we've already assigned an on-disk UUID
    NSString *uuid = [url to_makeFileSystemUUIDIfNeeded];

    // If the item is a directory, add it to the pending list to scan later
    if (url.to_isDirectory) {
        [pendingDirectories addObject:url];
    }
    
    // Check if the item had been moved
    if (![self verifyIfItemWasMovedOrDeletedWithURL:url uuid:uuid]) {
        return;
    }
    
    // Verify this file has a unique UUID.
    uuid = [self uniqueUUIDForItemAtURL:url withUUID:uuid];
    
    // Perform a verification of the item, and trigger the appropriate notifications
    [self verifyItemAtURL:url uuid:uuid];
}

- (BOOL)verifyItemIsNotMissingAtURL:(NSURL *)url
{
    // Exit out if we're not interested in tracking deleted files in this operation
    if (self.missingItems == nil) { return YES; }
    
    // Check if the file is still present at that URL
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        return YES;
    }
    
    // Look up in the all items store to see if we have a UUID
    NSString *uuid = [self.allItems uuidForItemWithURL:url];
    if (uuid == nil) { return NO; }
    
    // Save a reference to this file in case it turns up later in this operation
    self.missingItems[uuid] = url;
    
    return NO;
}

- (BOOL)verifyIfItemWasMovedOrDeletedWithURL:(NSURL *)url uuid:(NSString *)uuid
{
    NSURL *savedURL = self.allItems[uuid];
    if (savedURL == nil) { return YES; }
    
    // If the URLs match, the item hasn't been moved
    if ([savedURL isEqual:url]) {
        return YES;
    }
    
    // Check that the saved URL still has a file there, and the UUID of that file matches this one,
    // (in case the user deleted the file, then replaced it with one with the same name)
    NSString *savedUUID = [savedURL to_fileSystemUUID];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:savedURL.path];
    if (fileExists && [savedUUID isEqualToString:uuid]) {
        return YES;
    }
    
    // If the file still exists, but it was moved to the Trashes folder, this means
    // the user deleted it via the Files app. Instead of moving the file, override
    // and treat it like it was deleted.
    BOOL movedToTrashes = ([url.path rangeOfString:kTOFileSystemTrashFolderName].location != NSNotFound);
    if (movedToTrashes) {
        [self.allItems removeItemURLForUUID:uuid];
        [self.delegate scanOperation:self didDeleteItemAtURL:savedURL withUUID:uuid];
        return NO;
    }
    
    // We've confirmed that this file has been moved or renamed.
    
    // Update the store for the new location
    [self.allItems setItemURL:url forUUID:uuid];
    
    // If it was marked as potentially deleted, remove it from the deletion list
    [self.missingItems removeObjectForKey:uuid];
    
    // Post a notification that this operation happened
    [self.delegate scanOperation:self itemWithUUID:uuid didMoveFromURL:savedURL toURL:url];
    
    return YES;
}
- (void)verifyItemAtURL:(NSURL *)url uuid:(NSString *)uuid
{
    NSURL *savedURL = self.allItems[uuid];
    
    // There's an extremely specific edge case here.
    // If a user suspends the app, deletes an item, and then imports
    // a new item with the same name, we can import the new item easily,
    // but there's no easy way to work out which file entry was deleted.
    
    // To remedy this, use an inverse dictionary to access any previous UUID
    // values stored against this current URL, and if they don't match,
    // delete the previous entry
    NSString *savedUUID = [self.allItems uuidForItemWithURL:url];
    if (![savedUUID isEqualToString:uuid]) {
        [self.allItems removeItemURLForUUID:savedUUID];
        [self.delegate scanOperation:self didDeleteItemAtURL:url withUUID:savedUUID];
    }
    
    // Save/update the item to our master items list
    [self.allItems setItemURL:url forUUID:uuid];
    
    // If this item wasn't in the master store yet, trigger an alert that it was discovered
    // (On full scans, this happens regardless)
    if (!savedURL || self.directoryURL) {
        [self.delegate scanOperation:self didDiscoverItemAtURL:url withUUID:uuid];
        return;
    }
    
    // Otherwise, post a notification that "something" changed, so we should update it's state
    [self.delegate scanOperation:self itemDidChangeAtURL:url withUUID:uuid];
}

- (void)cleanUpFilesPendingDeletion
{
    if (self.missingItems.count == 0) { return; }
    
    // Loop through each missing item entry
    for (NSString *uuid in self.missingItems.allKeys) {
        // Remove it from the master store
        [self.allItems removeItemURLForUUID:uuid];
        
        // Trigger a delegate update event
        [self.delegate scanOperation:self didDeleteItemAtURL:self.missingItems[uuid] withUUID:uuid];
    }
}

#pragma mark - State Tracking -

- (NSString *)uniqueUUIDForItemAtURL:(NSURL *)url withUUID:(NSString *)uuid
{
    // Check if we already stored an item with that same UUID
    NSURL *savedURL = self.allItems[uuid];
    if (savedURL == nil) { return uuid; }
    
    // Check if the URLs match
    if ([url.URLByStandardizingPath isEqual:savedURL]) {
        return uuid;
    }
    
    // If the old one no longer exists, assume we moved files
    if (![[NSFileManager defaultManager] fileExistsAtPath:savedURL.path]) {
        return uuid;
    }
    
    // Otherwise, the user must have duplicated a file, so re-gen the UUID
    // and assign it to this file
    __block NSString *newUUID;
    [self.filePresenter performCoordinatedWrite:^{
        // Do a sanity check to verify the UUID didn't change while this queue was waiting
        newUUID = [url to_fileSystemUUID];
        if ([uuid isEqualToString:newUUID]) {
            newUUID = [url to_generateFileSystemUUID];
        }
    }];
        
    return newUUID;
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
