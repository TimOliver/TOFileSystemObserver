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

/** Lazily makes a URL enumerator at the base URL */
@property (nonatomic, strong) NSDirectoryEnumerator<NSURL *> *urlEnumerator;

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
    }

    return self;
}

#pragma mark - Scanning Implementation -

- (void)main
{
    // Start scanning every item we've discovered
    for (NSURL *url in self.urlEnumerator) {
        [self scanItemAtURL:url];
    }
}

- (void)scanItemAtURL:(NSURL *)url
{
    [self parentDirectoryItemForItemAtURL:url];

    // Check if we've already assigned an on-disk UUID
    NSString *uuid = [url to_fileSystemUUID];

    // If UUID is nil, it must be a new file
    if (uuid == nil) {
        // Create a new on-disk ID for it
        [url to_generateUUID];

        // Add the item to the database
        [self addNewItemAtURL:url];
    }
}

- (TOFileSystemItem *)parentDirectoryItemForItemAtURL:(NSURL *)url
{
    NSURL *topDirectory = self.directoryURL;

    // Build an array of all of the folders between our item, and the top
    NSMutableArray *directories = [NSMutableArray array];

    NSURL *parentItem = url;
    while (1) {
        // Loop up the file path until we reach the base directory where we started
        parentItem = parentItem.URLByDeletingLastPathComponent;

        // If we somehow miss the directory and continue up to the root of the device,
        // detect when we go over and just terminate
        if ([parentItem.lastPathComponent isEqualToString:@".."]) { break; }

        // If we reach the base directory from where we started, terminate
        if ([[parentItem to_fileSystemUUID] isEqualToString:self.directoryUUID]) {
            break;
        }

        // Save the directory name
        [directories insertObject:parentItem.lastPathComponent atIndex:0];
    }

    // Build

    return nil;
}

- (void)addNewItemAtURL:(NSURL *)newItemURL
{
    // Create a new object for this item
    TOFileSystemItem *item = [[TOFileSystemItem alloc] initWithItemAtFileURL:newItemURL];
    [self.realm transactionWithBlock:^{
        [self.realm addOrUpdateObject:item];
    }];

}

#pragma mark - File System Handling -

- (NSDirectoryEnumerator<NSURL *> *)urlEnumeratorForURL:(NSURL *)url
{
    if (_urlEnumerator) { return _urlEnumerator; }

    // Set the keys for the properties we wish to capture
    NSArray *keys = @[NSURLIsDirectoryKey,
                      NSURLFileSizeKey,
                      NSURLCreationDateKey,
                      NSURLContentModificationDateKey];

    // Set the flags for the enumerator
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles |
                                            NSDirectoryEnumerationSkipsSubdirectoryDescendants;

    _urlEnumerator = [self.fileManager enumeratorAtURL:url
                            includingPropertiesForKeys:keys
                                               options:options
                                          errorHandler:nil];
    return _urlEnumerator;
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
