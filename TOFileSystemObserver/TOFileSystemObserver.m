//
//  TOFileSystemObserver.m
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

#import "TOFileSystemObserver.h"

#import "TOFileSystemPath.h"
#import "TOFileSystemScanOperation.h"
#import "TOFileSystemPresenter.h"
#import "TOFileSystemItemList+Private.h"
#import "TOFileSystemItemURLDictionary.h"
#import "TOFileSystemItemMapTable.h"
#import "TOFileSystemItem+Private.h"

#import "NSURL+TOFileSystemUUID.h"

/** The instance held as the app-wide singleton */
static TOFileSystemObserver *_sharedObserver = nil;

@interface TOFileSystemObserver() <TOFileSystemScanOperationDelegate>

/** The absolute path to our observed directory's super directory so we can build paths. */
@property (nonatomic, strong) NSURL *parentDirectoryURL;

/** The UUID of the observed directory on disk, so we can easily access it in scans. */
@property (nonatomic, copy) NSString *baseDirectoryUUID;

/** Read-write access for the running state */
@property (nonatomic, assign, readwrite) BOOL isRunning;

/** Temporarily skip an event if we're explicitly touching the file system. */
@property (nonatomic, assign) BOOL skipEvents;

/** A file presenter object that will observe our file system */
@property (nonatomic, strong) TOFileSystemPresenter *fileSystemPresenter;

/** The operation queue we will perform our scanning on. */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/** A store for every item URL discovered on disk to ensure there are no duplicate UUIDs. */
@property (nonatomic, strong) TOFileSystemItemURLDictionary *allItems;

/** A map table that weakly holds item list objects */
@property (nonatomic, strong) TOFileSystemItemMapTable *itemListTable;

/** A map table that weakly holds any items currently being presented. */
@property (nonatomic, strong) TOFileSystemItemMapTable *itemTable;

@end

@implementation TOFileSystemObserver

#pragma mark - Object Lifecycle -

- (instancetype)init
{
    if (self = [super init]) {
        _directoryURL = [TOFileSystemPath documentsDirectoryURL].URLByStandardizingPath;
        [self setUp];
    }

    return self;
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
{
    if (self = [super init]) {
        _directoryURL = directoryURL;
        [self setUp];
    }

    return self;
}

+ (instancetype)sharedObserver
{
    if (_sharedObserver) { return _sharedObserver; }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObserver = [[TOFileSystemObserver alloc] init];
    });
    
    return _sharedObserver;
}

+ (void)setSharedObserver:(TOFileSystemObserver *)observer
{
    if (observer == _sharedObserver) { return; }
    if (_sharedObserver.isRunning) {
        [_sharedObserver stop];
    }
    
    _sharedObserver = observer;
}

- (void)setUp
{
    // Set-up default property values
    _isRunning = NO;
    _excludedItems = @[@"Inbox"];
    
    // Set-up the operation queue
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    _operationQueue.qualityOfService = NSQualityOfServiceBackground;

    // Set up the file system presenter
    _fileSystemPresenter = [[TOFileSystemPresenter alloc] init];
    
    // Set up the map tables
    _itemListTable  = [[TOFileSystemItemMapTable alloc] init];
    _itemTable      = [[TOFileSystemItemMapTable alloc] init];
    
    // Set up the stores for tracking items
    _allItems = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.directoryURL];
}

#pragma mark - Observer Setup -

- (void)configureFilePresenter
{
    // Attach the root directory to the observer
    NSURL *url = self.directoryURL;
    self.fileSystemPresenter.directoryURL = url;
    
    // Set up the callback handler for when changes are detected
    __weak typeof(self) weakSelf = self;
    self.fileSystemPresenter.itemsDidChangeHandler = ^(NSArray *itemURLs) {
        [weakSelf updateObservingObjectsWithChangedItemURLs:itemURLs];
    };
}

- (void)beginObservingBaseDirectory
{
    // Configure the file presenter and start
    [self configureFilePresenter];
    [self.fileSystemPresenter start];
}

#pragma mark - Observer Lifecycle -

- (void)start
{
    if (self.isRunning) { return; }

    // Set the running state
    self.isRunning = YES;

    // Lock in the properties of the base directory
    _parentDirectoryURL = [_directoryURL URLByDeletingLastPathComponent];
    _baseDirectoryUUID = self.directoryItem.uuid;

    // Start the observer to watch for any system level changes
    [self beginObservingBaseDirectory];
    
    // Perform an initial scan of all of the files we will observe
    [self performFullDirectoryScan];
}

- (void)stop
{
    if (!self.isRunning) { return; }
    
    // Set the running state to off
    self.isRunning = NO;

    // Clear out all of the items in memory (since we'll do a rebuild next time)
    [self.allItems removeAllItems];
    
    // Remove all of the observers
    [self.fileSystemPresenter stop];
}

#pragma mark - Scanning -

- (void)performFullDirectoryScan
{
    // Create a new scan operation
    TOFileSystemScanOperation *scanOperation = nil;
    scanOperation = [[TOFileSystemScanOperation alloc] initWithDirectoryAtURL:self.directoryURL
                                                           allItemsDictionary:self.allItems
                                                                filePresenter:self.fileSystemPresenter];
    scanOperation.subDirectoryLevelLimit = self.includedDirectoryLevels;
    scanOperation.delegate = self;
    
    // Begin asynchronous execution
    [self.operationQueue addOperation:scanOperation];
}

#pragma mark - Creating Observing Objects -

- (TOFileSystemItemList *)itemListForDirectoryAtURL:(NSURL *)directoryURL
{
    // Default to the base directory if nil is supplied
    if (directoryURL == nil) {
        directoryURL = self.directoryURL;
    }
    
    // Create a block to generate or re-fetch a list object
    __block TOFileSystemItemList *itemList = nil;
    void (^getListBlock)(void) = ^{
        @autoreleasepool {
            // Fetch the UUID for this item and see if we've cached it already
            NSString *uuid = [directoryURL to_fileSystemUUID];
            uuid = [self verifiedUniqueUUIDForItemAtURL:directoryURL uuid:uuid];
            itemList = self.itemListTable[uuid];
            if (itemList) { return; }
            
            // Create a new one, and save it to the map table
            itemList = [[TOFileSystemItemList alloc] initWithDirectoryURL:directoryURL
                                                       fileSystemObserver:self];
            self.itemListTable[uuid] = itemList;
            self.allItems[uuid] = directoryURL;
        }
    };
    
    // Since map tables can internally mutate, perform all access on the main thread
    if (![NSThread isMainThread]) {
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_sync(mainQueue, getListBlock);
    }
    else {
        getListBlock();
    }

    return itemList;
}

- (TOFileSystemItem *)itemForFileAtURL:(NSURL *)fileURL
{
    // Exit out if the URL is invalid
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        return nil;
    }
    
    // Create a block to generate or re-fetch an existing object
    __block TOFileSystemItem *item = nil;
    void (^getItemBlock)(void) = ^{
        @autoreleasepool {
            // Fetch the UUID for this item and see if we've cached it already
            NSString *uuid = [fileURL to_fileSystemUUID];
            uuid = [self verifiedUniqueUUIDForItemAtURL:fileURL uuid:uuid];
            item = self.itemTable[uuid];
            if (item) { return; }
            
            // Create a new one, and save it to the map table
            item = [[TOFileSystemItem alloc] initWithItemAtFileURL:fileURL
                                                fileSystemObserver:self];
            self.itemTable[uuid] = item;
            self.allItems[uuid] = fileURL;
        }
    };
    
    // Since map tables can internally mutate, perform all access on the main thread
    if (![NSThread isMainThread]) {
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_sync(mainQueue, getItemBlock);
    }
    else {
        getItemBlock();
    }

    return item;
}

#pragma mark - Handling UUID Redundancy -

- (NSString *)verifiedUniqueUUIDForItemAtURL:(NSURL *)itemURL uuid:(NSString *)uuid
{
    // If it was detected that there are two items with the same UUID
    // in the master list, regenerate the UUID for this one
    
    // If this item isn't in the master list yet, then there is no chance for conflicts
    NSURL *url = self.allItems[uuid];
    if (url == nil) { return uuid; }
    
    // If an item does exist, check it is at the same location
    if ([url.URLByStandardizingPath isEqual:itemURL.URLByStandardizingPath]) {
        return uuid;
    }
    
    // If the file no longer exists at the URL in the store, assume it was moved
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [self.allItems removeItemURLForUUID:uuid];
        return uuid;
    }
    
    // If another file with the same UUID exists alongside this one, they are clearly duplicated.
    // Create a new UUID for this item
    __block NSString *newUUID = nil;
    [self.fileSystemPresenter performCoordinatedWrite:^{
        // Do a sanity check to verify the UUID didn't change while this queue was waiting
        newUUID = [itemURL to_fileSystemUUID];
        if ([uuid isEqualToString:newUUID]) {
            newUUID = [itemURL to_generateFileSystemUUID];
        }
    }];
    
    return newUUID;
}

#pragma mark - File System Change Notifications -

- (void)updateObservingObjectsWithChangedItemURLs:(NSArray *)itemURLs
{
    // Create a new scan operation to analyse what changed
    TOFileSystemScanOperation *scanOperation = nil;
    scanOperation = [[TOFileSystemScanOperation alloc] initWithItemURLs:itemURLs
                                                           allItemsDictionary:self.allItems
                                                                filePresenter:self.fileSystemPresenter];
    scanOperation.subDirectoryLevelLimit = self.includedDirectoryLevels;
    scanOperation.delegate = self;

    // Begin asynchronous execution
    [self.operationQueue addOperation:scanOperation];
}

#pragma mark - Scan Operation Delegate -

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
 didDiscoverItemAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    // Fetch the UUID of the parent in case it needs to be appended to a list
    NSString *parentUUID = [itemURL to_uuidForParentDirectory];
    
    // If this item has an entry, refresh it
    [self.itemTable[uuid] refreshWithURL:itemURL];
    
    // If this item is a child of another item, update the parent item
    [self.itemTable[parentUUID] refreshWithURL:nil];
    
    // If this item is a list itself, update it's list entry
    [self.itemListTable[uuid] refreshWithURL:itemURL];
    
    id mainBlock = ^{
        @autoreleasepool {
            // If this is a new item that belongs to an existing list, append it
            TOFileSystemItemList *list = self.itemListTable[parentUUID];
            [list addItemWithUUID:uuid itemURL:itemURL];
        }
        
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
   itemDidChangeAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    // See if there is a list had been made for the parent, and add it
    NSString *parentUUID = [itemURL to_uuidForParentDirectory];
    
    // See if this item exists in either of our stores, and if so, trigger a refresh
    [self.itemTable[uuid] refreshWithURL:itemURL];
    [self.itemListTable[uuid] refreshWithURL:itemURL];
    
    // If this item is a child of another item, update that one
    [self.itemTable[parentUUID] refreshWithURL:nil];
    
    id mainBlock = ^{
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
         itemWithUUID:(NSString *)uuid
        didMoveFromURL:(NSURL *)previousURL
                toURL:(NSURL *)url
{
    // If the movement occurred inside the same folder (eg, it was renamed),
    // cancel out here.
    NSURL *oldParentURL = previousURL.URLByDeletingLastPathComponent.URLByStandardizingPath;
    NSURL *newParentURL = url.URLByDeletingLastPathComponent.URLByStandardizingPath;
    if ([oldParentURL isEqual:newParentURL]) { return; }
    
    // See if moved from, or into a new list
    NSString *oldParentUUID = [oldParentURL to_fileSystemUUID];
    NSString *newParentUUID = [newParentURL to_fileSystemUUID];
    
    // Get the item and refresh its internal state for the new location
    TOFileSystemItem *item = self.itemTable[uuid];
    [item refreshWithURL:url];
    
    // If this item is a list itself, update its list entry too
    TOFileSystemItemList *list = self.itemListTable[uuid];
    [list refreshWithURL:url];
    
    // If the item used to be in a specific list, remove it
    TOFileSystemItemList *oldList = self.itemListTable[oldParentUUID];
    [item removeFromList:oldList];
    
    // If that old list is represented as an item, refresh it
    TOFileSystemItem *oldListItem = self.itemTable[oldParentUUID];
    [oldListItem refreshWithURL:oldListItem.fileURL];
    
    // If the item was moved to a new list, add it to that list
    TOFileSystemItemList *newList = self.itemListTable[newParentUUID];
    [item addToList:newList];
    
    // If the new list is an item, refresh that too
    TOFileSystemItem *newListItem = self.itemTable[newParentUUID];
    [newListItem refreshWithURL:newListItem.fileURL];
    
    id mainBlock = ^{
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
   didDeleteItemAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    NSString *parentUUID = [itemURL to_uuidForParentDirectory];
    
    id mainBlock = ^{
        // If we have this item in memory, remove it from everywhere
        TOFileSystemItem *item = self.itemTable[uuid];
        [item removeFromAllLists];
        [self.itemTable removeItemForUUID:uuid];
        [self.itemListTable removeItemForUUID:uuid];
        
        // If this item is a child of a list, update that list
        TOFileSystemItem *listItem = self.itemTable[parentUUID];
        [listItem refreshWithURL:listItem.fileURL];
        
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

@end
