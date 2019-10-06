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
#import "TOFileSystemRealmConfiguration.h"
#import "TOFileSystemSourceCollection.h"
#import "NSURL+TOFileSystemUUID.h"

#import <Realm/Realm.h>

@interface TOFileSystemScanOperation ()

/** The sources object that stores all of the dispatch source objects. */
@property (nonatomic, strong) TOFileSystemSourceCollection *sourcesCollection;

/** A thread-safe reference to the Realm file holding our state */
@property (nonatomic, strong) RLMRealmConfiguration *realmConfiguration;

/** A copy of the base item UUID so it can be accessed on separate threads */
@property (nonatomic, copy) NSString *directoryUUID;

/** The URL to the base directory */
@property (nonatomic, strong) NSURL *directoryURL;

/** A local file manager object we can use for retrieving disk contents. */
@property (nonatomic, strong) NSFileManager *fileManager;

/** Generate a thread safe instance of the Realm object */
@property (nonatomic, readonly) RLMRealm *realm;

/** The file system item representing the base directory. */
@property (nonatomic, readonly) TOFileSystemItem *item;

/** When iterating through all the files, this array stores pending directories that need scanning*/
@property (nonatomic, strong) NSMutableArray *pendingDirectories;

@end

@implementation TOFileSystemScanOperation

#pragma - Class Lifecycle -

- (instancetype)initWithDirectoryItem:(TOFileSystemItem *)directoryItem
                   realmConfiguration:(RLMRealmConfiguration *)realmConfiguration
                    sourcesCollection:(TOFileSystemSourceCollection *)sourcesCollection
{
    if (self = [super init]) {
        _directoryUUID = directoryItem.uuid;
        _realmConfiguration = realmConfiguration;
        _directoryURL = directoryItem.absoluteFileURL;
        _subDirectoryLevelLimit = -1;
        _fileManager = [[NSFileManager alloc] init];
        _pendingDirectories = [NSMutableArray array];
        _sourcesCollection = sourcesCollection;
    }

    return self;
}

#pragma mark - Scanning Implementation -

- (void)main
{
    NSMutableArray *pendingDirectories = self.pendingDirectories;

    // Start scanning every item in our base directory
    NSDirectoryEnumerator *enumerator = [self urlEnumeratorForURL:self.directoryURL];
    for (NSURL *url in enumerator) {
        [self scanItemAtURL:url pendingDirectories:pendingDirectories];
    }

    // If there were any directories in the base, start a flat loop to scan
    // all subdirectories too (Avoiding potential stack overflows!)
    while (pendingDirectories.count > 0) {
        // Extract the item, and then remove it from the pending list
        NSURL *url = pendingDirectories.firstObject;
        [pendingDirectories removeObjectAtIndex:0];

        // Create a new enumerator for it
        enumerator = [self urlEnumeratorForURL:url];
        for (NSURL *url in enumerator) {
            [self scanItemAtURL:url pendingDirectories:pendingDirectories];
        }
    }
}

- (void)scanItemAtURL:(NSURL *)url pendingDirectories:(NSMutableArray *)pendingDirectories
{
    // Obtain a thread safe reference to Realm
    RLMRealm *realm = self.realm;

    // Check if we've already assigned an on-disk UUID
    NSString *uuid = [url to_fileSystemUUID];
    TOFileSystemItem *item = [TOFileSystemItem objectInRealm:realm forPrimaryKey:uuid];

    // If UUID is nil, or if it's not already in the DB, insert it
    if (uuid == nil || item == nil) {
        // Add the item to the database
        item = [self addNewItemAtURL:url];
    }
    else {

    }

    // If the item is a directory
    if (item.type == TOFileSystemItemTypeDirectory) {
        // Add it to the pending list so we can start scanning it after this
        [pendingDirectories addObject:url];

        // Register it for observable changes
        [self.sourcesCollection addDirectoryAtURL:url uuid:uuid];
    }
}

- (TOFileSystemItem *)itemForParentOfItemAtURL:(NSURL *)url
{
    NSString *uuid = [url.URLByDeletingLastPathComponent to_fileSystemUUID];
    NSAssert(uuid.length > 0, @"The parent item should always exist before children");

    TOFileSystemItem *item = [TOFileSystemItem objectInRealm:self.realm forPrimaryKey:uuid];
    NSAssert(item != nil, @"Parent should already exist at this point");

    return item;
}

- (TOFileSystemItem *)addNewItemAtURL:(NSURL *)newItemURL
{
    // Get a reference to the parent directory
    TOFileSystemItem *parentItem = [self itemForParentOfItemAtURL:newItemURL];

    // Create a new object for this item (and assign its parent)
    TOFileSystemItem *item = [[TOFileSystemItem alloc] initWithItemAtFileURL:newItemURL];

    // Add the item to Realm, and assign it as a child to the parent
    [self.realm transactionWithBlock:^{
        [self.realm addOrUpdateObject:item];
        [parentItem.childItems addObject:item];
    }];

    return item;
}

#pragma mark - File System Handling -

- (NSDirectoryEnumerator<NSURL *> *)urlEnumeratorForURL:(NSURL *)url
{
    // Set the keys for the properties we wish to capture
    NSArray *keys = @[NSURLIsDirectoryKey,
                      NSURLFileSizeKey,
                      NSURLCreationDateKey,
                      NSURLContentModificationDateKey];

    // Set the flags for the enumerator
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles |
                                            NSDirectoryEnumerationSkipsSubdirectoryDescendants;

    // Create the enumerator
    NSDirectoryEnumerator<NSURL *> *urlEnumerator = [self.fileManager enumeratorAtURL:url
                                                           includingPropertiesForKeys:keys
                                                                              options:options
                                                                         errorHandler:nil];
    return urlEnumerator;
}

#pragma mark - Convenience Accessors -

- (RLMRealm *)realm
{
    return [RLMRealm realmWithConfiguration:self.realmConfiguration error:nil];
}

- (TOFileSystemItem *)item
{
    return [TOFileSystemItem objectInRealm:self.realm forPrimaryKey:self.directoryUUID];
}

@end
