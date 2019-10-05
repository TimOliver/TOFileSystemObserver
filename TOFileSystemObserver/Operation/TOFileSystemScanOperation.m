//
//  TOFileSystemScanOperation.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemScanOperation.h"
#import "TOFileSystemItem.h"
#import "TOFileSystemRealmConfiguration.h"
#import "NSURL+TOFileSystemUUID.h"

#import <Realm/Realm.h>

@interface TOFileSystemScanOperation ()

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
{
    if (self = [super init]) {
        _directoryUUID = directoryItem.uuid;
        _realmConfiguration = realmConfiguration;
        _directoryURL = directoryItem.absoluteFileURL;
        _subDirectoryLevelLimit = -1;
        _fileManager = [[NSFileManager alloc] init];
        _pendingDirectories = [NSMutableArray array];
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

    // If the item is a directory, add it to pending so we know to scan it as well
    if (item.type == TOFileSystemItemTypeDirectory) {
        [pendingDirectories addObject:url];
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
