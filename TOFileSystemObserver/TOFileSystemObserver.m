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
#import "TOFileSystemNotificationToken.h"
#import "TOFileSystemNotificationToken+Private.h"
#import "TOFileSystemObserverConstants.h"
#import "TOFileSystemChanges+Private.h"

#import "NSURL+TOFileSystemUUID.h"
#import "NSURL+TOFileSystemAttributes.h"

// Because the block is stored as a generic id, we must cast it back before we can call it.
static inline void TOFileSystemObserverCallBlock(id block, id observer, NSInteger type, id changes) {
    TOFileSystemNotificationBlock _block = (TOFileSystemNotificationBlock)block;
    _block(observer, type, changes);
};

NSNotificationName const TOFileSystemObserverWillBeginFullScanNotification
                            = @"TOFileSystemObserverWillBeginFullScan";
NSNotificationName const TOFileSystemObserverDidCompleteFullScanNotification
                            = @"TOFileSystemObserverDidCompleteFullScan";
NSNotificationName const TOFileSystemObserverDidChangeNotification
                            = @"TOFileSystemObserverDidChangeNotification";

NSString * const TOFileSystemObserverUserInfoKey
                            = @"TOFileSystemObserverUserInfoKey";
NSString * const TOFileSystemObserverChangesUserInfoKey
                            = @"TOFileSystemObserverChangesUserInfoKey";

/** The instance held as the app-wide singleton */
static TOFileSystemObserver *_sharedObserver = nil;

@interface TOFileSystemObserver() <TOFileSystemScanOperationDelegate, TOFileSystemNotifying>

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

/** A thread-safe store for every item URL discovered on disk to ensure there are no duplicate UUIDs. */
@property (nonatomic, strong) TOFileSystemItemURLDictionary *allItems;

/** A thread-safe store for items that were observered to still being copied during the last update. */
@property (nonatomic, strong) TOFileSystemItemURLDictionary *copyingItems;

/** A timer that will fire after a few seconds to attempt to clean up any copying files. */
@property (nonatomic, strong) NSTimer *copyingTimer;

/** A map table that weakly holds item list objects */
@property (nonatomic, strong) TOFileSystemItemMapTable *itemListTable;

/** A map table that weakly holds any items currently being presented. */
@property (nonatomic, strong) TOFileSystemItemMapTable *itemTable;

/** A hash table containing all of the notification blocks/tokens registered to this observer. */
@property (nonatomic, strong) NSHashTable *notificationTokens;

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
        _sharedObserver.broadcastsNotifications = YES;
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
    _includedDirectoryLevels = -1;
    
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
    _copyingItems = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.directoryURL];
    
    // Change the UUID key name to match our app (for better visibility)
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    [NSURL to_setKeyNamePrefix:bundleIdentifier];
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

- (void)performFullDirectoryScan
{
    // Create a new scan operation
    TOFileSystemScanOperation *scanOperation = nil;
    scanOperation = [[TOFileSystemScanOperation alloc] initForFullScanWithDirectoryAtURL:self.directoryURL
                                                                           skippingItems:self.excludedItems
                                                                      allItemsDictionary:self.allItems
                                                                           filePresenter:self.fileSystemPresenter];
    scanOperation.subDirectoryLevelLimit = self.includedDirectoryLevels;
    scanOperation.delegate = self;
    
    // Begin asynchronous execution
    [self.operationQueue addOperation:scanOperation];
}

- (void)updateObservingObjectsWithChangedItemURLs:(NSArray *)itemURLs
{
    // Create a new scan operation to analyse what changed
    TOFileSystemScanOperation *scanOperation = nil;
    scanOperation = [[TOFileSystemScanOperation alloc] initForItemScanWithItemURLs:itemURLs
                                                                           baseURL:self.directoryURL
                                                                     skippingItems:self.excludedItems
                                                                allItemsDictionary:self.allItems
                                                                     filePresenter:self.fileSystemPresenter];
    scanOperation.subDirectoryLevelLimit = self.includedDirectoryLevels;
    scanOperation.delegate = self;

    // Begin asynchronous execution
    [self.operationQueue addOperation:scanOperation];
}

- (TOFileSystemNotificationToken *)addNotificationBlock:(TOFileSystemNotificationBlock)block
{
    TOFileSystemNotificationToken *token = [TOFileSystemNotificationToken tokenWithObservingObject:self block:block];
    if (self.notificationTokens == nil) {
        self.notificationTokens = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [self.notificationTokens addObject:token];
    return token;
}

/** Removes the notification from the observing object. */
- (void)removeNotificationToken:(TOFileSystemNotificationToken *)token
{
    [self.notificationTokens removeObject:token];
}

#pragma mark - Creating and Observing Items -

- (nullable NSString *)uuidForItemAtURL:(NSURL *)itemURL
{
    // See if we already have a UUID entry for this file in the global store
    __block NSString *uuid = nil;
    uuid = [self.allItems uuidForItemWithURL:itemURL];
    if (uuid.length) { return uuid; }
    
    // If it's not in the store, perform a sanity check that the file exists
    // before we start doing potentially long file
    if (![[NSFileManager defaultManager] fileExistsAtPath:itemURL.path]) {
        return nil;
    }
    
    // Defer to the file presenter to perform a thread-safe access of the UUID
    // string associated with the file
    return [self.fileSystemPresenter uuidForItemAtURL:itemURL];
}

- (nullable NSString *)uuidForParentOfItemAtURL:(NSURL *)itemURL
{
    return [self uuidForItemAtURL:itemURL.URLByDeletingLastPathComponent];
}

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
            NSString *uuid = [self uuidForItemAtURL:directoryURL];
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
            NSString *uuid = [self uuidForItemAtURL:fileURL];
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

#pragma mark - Item Refreshing -

- (BOOL)refreshItemAtURL:(NSURL *)itemURL
                    uuid:(NSString *)uuid
{
    // Perform an update on the item and see if we need to trigger
    // any visual updates
    BOOL hasChanges = [self.itemTable[uuid] refreshWithURL:itemURL];
    
    // If the item is also in memory as a list, update its list entry too
    [self.itemListTable[uuid] refreshWithURL:itemURL];
    
    return hasChanges;
}

- (BOOL)refreshParentItemWithUUID:(NSString *)uuid
{
    // If the parent item is an item, do a check on it to see if it has changes
    BOOL hasChanges = [self.itemTable[uuid] refreshWithURL:nil];
    
    // If the parent item has a list entry, perform an update on that too
    [self.itemListTable[uuid] refreshWithURL:nil];
    
    return hasChanges;
}

- (void)startTimerForCopyingItems
{
    id block = ^{
        // The timer is already counting down
        if (self.copyingTimer) { return; }
        
        // Create a new timer
        self.copyingTimer = [NSTimer timerWithTimeInterval:kTOFileSystemObserverCopyingTimeDelay
                                                    target:self
                                                  selector:@selector(copyTimerCompleted)
                                                  userInfo:nil
                                                   repeats:NO];
        
        // Start the timer
        [[NSRunLoop currentRunLoop] addTimer:self.copyingTimer forMode:NSDefaultRunLoopMode];
    };
    
    // Run this on the main thread in order to attach it to the main run loop
    [[NSOperationQueue mainQueue] addOperationWithBlock:block];
}

- (void)copyTimerCompleted
{
    // Remove the timer
    self.copyingTimer = nil;
    
    id block =  ^{
        // Get all of the URLs still pending in the dictionary
        NSArray *urls = self.copyingItems.allURLs;
        if (urls == nil) { return; }
        
        // Remove all the items we're about to test from the list,
        // as they'll be re-added on the subsequent callback if they're
        // still copying
        [self.copyingItems removeAllItems];
        
        // Perform a scan to see if they've changed
        [self updateObservingObjectsWithChangedItemURLs:urls];
    };
    
    [self.operationQueue addOperationWithBlock:block];
}

#pragma mark - Scan Operation Delegate -

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
 didDiscoverItemAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    // Get the UUID of the parent so we can see if there is a list for it
    NSString *parentUUID = [self uuidForParentOfItemAtURL:itemURL];
    
    // Refresh all of the properties of this item and its parent
    [self refreshItemAtURL:itemURL uuid:uuid];
    [self refreshParentItemWithUUID:parentUUID];
    
    // Broadcast this event to all of the observers.
    TOFileSystemChanges *changes = [[TOFileSystemChanges alloc] initWithFileSystemObserver:self];
    if (scanOperation.isFullScan) { [changes setIsFullScan]; }
    [changes addDiscoveredItemWithUUID:uuid fileURL:itemURL];
    [self postNotificationsWithChanges:changes];
    
    id mainBlock = ^{
        // If this is a new item that belongs to an existing list, append it
        TOFileSystemItemList *parentList = self.itemListTable[parentUUID];
        if (parentList) { [parentList addItemWithUUID:uuid itemURL:itemURL]; }
    };
    [[NSOperationQueue mainQueue] addOperationWithBlock:mainBlock];
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
   itemDidChangeAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    // If the item is still copying at this point (Potentially lag during the write?)
    // add it to our copying list so we can poll it again in a few seconds
    if (itemURL.to_isCopying) {
        [self.copyingItems setItemURL:itemURL forUUID:uuid];
        [self startTimerForCopyingItems];
    }
    
    // See if there is a list had been made for the parent, and add it
    NSString *parentUUID = [self uuidForParentOfItemAtURL:itemURL];
    [self refreshItemAtURL:itemURL uuid:uuid];
    [self refreshParentItemWithUUID:parentUUID];
    
    // Broadcast this event to all of the observers.
    TOFileSystemChanges *changes = [[TOFileSystemChanges alloc] initWithFileSystemObserver:self];
    if (scanOperation.isFullScan) { [changes setIsFullScan]; }
    [changes addModifiedItemWithUUID:uuid fileURL:itemURL];
    [self postNotificationsWithChanges:changes];
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
    
    // Get the item and refresh its internal state with the new location
    [self refreshItemAtURL:url uuid:uuid];
    
    // Refresh both of the parents to update the children counts in each
    [self refreshParentItemWithUUID:oldParentUUID];
    [self refreshParentItemWithUUID:newParentUUID];

    // Broadcast this event to all of the observers.
    TOFileSystemChanges *changes = [[TOFileSystemChanges alloc] initWithFileSystemObserver:self];
    if (scanOperation.isFullScan) { [changes setIsFullScan]; }
    [changes addMovedItemWithUUID:uuid oldFileURL:previousURL newFileURL:url];
    [self postNotificationsWithChanges:changes];
    
    id mainBlock = ^{
        // If the item used to be in a list item, remove it from that list
        TOFileSystemItemList *oldList = self.itemListTable[oldParentUUID];
        [oldList removeItemWithUUID:uuid fileURL:url];
        
        // If the destination also had a list, append it to that list
        TOFileSystemItemList *newList = self.itemListTable[newParentUUID];
        [newList addItemWithUUID:uuid itemURL:url];
    };
    [[NSOperationQueue mainQueue] addOperationWithBlock:mainBlock];
}

- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
   didDeleteItemAtURL:(NSURL *)itemURL
             withUUID:(NSString *)uuid
{
    NSString *parentUUID = [self uuidForParentOfItemAtURL:itemURL];
    
    // Broadcast this event to all of the observers.
    TOFileSystemChanges *changes = [[TOFileSystemChanges alloc] initWithFileSystemObserver:self];
    if (scanOperation.isFullScan) { [changes setIsFullScan]; }
    [changes addDeletedItemWithUUID:uuid fileURL:itemURL];
    [self postNotificationsWithChanges:changes];
    
    id mainBlock = ^{
        // If we have this item in memory, remove it from everywhere
        TOFileSystemItem *item = self.itemTable[uuid];
        [item.list removeItemWithUUID:uuid fileURL:itemURL];
        [self.itemTable removeItemForUUID:uuid];
        [self.itemListTable removeItemForUUID:uuid];
        
        // If this item is a child of a list, update that list
        TOFileSystemItem *listItem = self.itemTable[parentUUID];
        [listItem refreshWithURL:nil];
    };
    [[NSOperationQueue mainQueue] addOperationWithBlock:mainBlock];
}

- (void)scanOperationWillBeginFullScan:(TOFileSystemScanOperation *)scanOperation
{
    // Perform the Notification Center broadcast
    if (self.broadcastsNotifications) {
        NSDictionary *userInfo = [self userInfoDictionaryWithChanges:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:TOFileSystemObserverWillBeginFullScanNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
    
    // Inform all notification tokens registered
    for (TOFileSystemNotificationToken *token in self.notificationTokens) {
        TOFileSystemObserverCallBlock(token.notificationBlock,
                                      self,
                                      TOFileSystemObserverNotificationTypeWillBeginFullScan,
                                      nil);
    }
}

- (void)scanOperationDidCompleteFullScan:(TOFileSystemScanOperation *)scanOperation
{
    // Loop through the list one more time to remove any headless entries
    for (NSString *listUUID in self.itemListTable) {
        [self.itemListTable[listUUID] synchronizeWithDisk];
    }
    
    // Perform the Notification Center broadcast
    if (self.broadcastsNotifications) {
        NSDictionary *userInfo = [self userInfoDictionaryWithChanges:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:TOFileSystemObserverDidCompleteFullScanNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
    
    // Inform all notification tokens registered
    for (TOFileSystemNotificationToken *token in self.notificationTokens) {
        TOFileSystemObserverCallBlock(token.notificationBlock,
                                      self,
                                      TOFileSystemObserverNotificationTypeDidCompleteFullScan,
                                      nil);
    }
}

#pragma mark - Notifications -

- (NSDictionary *)userInfoDictionaryWithChanges:(TOFileSystemChanges *)changes
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[TOFileSystemObserverUserInfoKey] = self;
    if (changes) {
        dictionary[TOFileSystemObserverChangesUserInfoKey] = changes;
    }
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (void)postNotificationsWithChanges:(TOFileSystemChanges *)changes
{
    if (!self.broadcastsNotifications && self.notificationTokens.count == 0) {
        return;
    }
    
    // Perform the Notification Center broadcast
    if (self.broadcastsNotifications) {
        NSDictionary *userInfo = [self userInfoDictionaryWithChanges:changes];
        [[NSNotificationCenter defaultCenter] postNotificationName:TOFileSystemObserverDidChangeNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
    
    // Inform all notification tokens registered
    for (TOFileSystemNotificationToken *token in self.notificationTokens) {
        TOFileSystemObserverCallBlock(token.notificationBlock,
                                      self,
                                      TOFileSystemObserverNotificationTypeDidChange,
                                      changes);
    }
}

@end
