//
//  TOFileSystemObserver.m
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

#import "TOFileSystemObserver.h"

#import "TOFileSystemPath.h"
#import "TOFileSystemScanOperation.h"
#import "TOFileSystemPresenter.h"
#import "TOFileSystemItemList+Private.h"
#import "TOFileSystemItemDictionary.h"
#import "TOFileSystemItem+Private.h"

#import "NSURL+TOFileSystemUUID.h"

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
@property (nonatomic, strong) TOFileSystemItemDictionary *allItems;

/** A map table that weakly holds item list objects */
@property (nonatomic, strong) NSMapTable *itemListTable;

/** A map table that weakly holds any items currently being presented. */
@property (nonatomic, strong) NSMapTable *itemTable;

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
    _itemListTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                               valueOptions:NSPointerFunctionsWeakMemory
                                                   capacity:0];
    _itemTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                           valueOptions:NSPointerFunctionsWeakMemory
                                               capacity:0];
    
    // Set up the stores for tracking items
    _allItems = [[TOFileSystemItemDictionary alloc] initWithBaseURL:self.directoryURL];
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

    // Configure the source observer to send change events to us
    [self configureFilePresenter];

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
        // Fetch the UUID for this item and see if we've cached it already
        NSString *uuid = [directoryURL to_fileSystemUUID];
        uuid = [self verifiedUniqueUUIDForItemAtURL:directoryURL uuid:uuid];
        itemList = [self.itemListTable objectForKey:uuid];
        if (itemList) { return; }
        
        // Create a new one, and save it to the map table
        itemList = [[TOFileSystemItemList alloc] initWithDirectoryURL:directoryURL
                                                                         fileSystemObserver:self];
        [self.itemListTable setObject:itemList forKey:itemList.uuid];
        self.allItems[uuid] = directoryURL;
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
        // Fetch the UUID for this item and see if we've cached it already
        NSString *uuid = [fileURL to_fileSystemUUID];
        uuid = [self verifiedUniqueUUIDForItemAtURL:fileURL uuid:uuid];
        item = [self.itemTable objectForKey:uuid];
        if (item) { return; }
        
        // Create a new one, and save it to the map table
        item = [[TOFileSystemItem alloc] initWithItemAtFileURL:fileURL fileSystemObserver:self];
        [self.itemTable setObject:item forKey:item.uuid];
        self.allItems[uuid] = fileURL;
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
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self.fileSystemPresenter];
    [fileCoordinator coordinateWritingItemAtURL:itemURL options:0 error:nil byAccessor:^(NSURL * _Nonnull newURL) {
        newUUID = [newURL to_generateFileSystemUUID];
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
    // See if there is a list had been made for the parent, and add it
    NSString *parentUUID = [itemURL to_uuidForParentDirectory];
    id mainBlock = ^{
        TOFileSystemItemList *list = [self.itemListTable objectForKey:parentUUID];
        [list addItemWithUUID:uuid itemURL:itemURL];
        
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
   itemDidChangeAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    id mainBlock = ^{
        // See if this item exists in memory, and if so, trigger a refresh
        TOFileSystemItem *item = [self.itemTable objectForKey:uuid];
        [item refreshWithURL:itemURL];
        
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
         itemWithUUID:(NSString *)uuid
        didMoveFromURL:(NSURL *)previousURL
                toURL:(NSURL *)url
{
    // See if moved from, or into a new list
    NSString *oldParentUUID = [previousURL to_uuidForParentDirectory];
    NSString *newParentUUID = [url to_uuidForParentDirectory];
    
    id mainBlock = ^{
        // Get the item and refresh its internal state for the new location
        TOFileSystemItem *item = [self.itemTable objectForKey:uuid];
        [item refreshWithURL:url];
        
        // Potentially remove it from the old list
        TOFileSystemItemList *oldList = [self.itemListTable objectForKey:oldParentUUID];
        [item removeFromList:oldList];
        
        // Potentially add it to a new list
        TOFileSystemItemList *newList = [self.itemListTable objectForKey:newParentUUID];
        [item addToList:newList];
        
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
   didDeleteItemAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    id mainBlock = ^{
        // If we have this item in memory, remove it from everywhere
        TOFileSystemItem *item = [self.itemTable objectForKey:uuid];
        [item removeFromAllLists];
        [self.itemTable removeObjectForKey:uuid];
        
        // TODO: Add broadcast notifications
    };
    dispatch_async(dispatch_get_main_queue(), mainBlock);
}

@end
