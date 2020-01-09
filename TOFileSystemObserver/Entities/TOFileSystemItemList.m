//
//  TOFileSystemList.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 10/11/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemItemList.h"
#import "TOFileSystemItem.h"
#import "TOFileSystemItem+Private.h"
#import "TOFileSystemObserver.h"
#import "TOFileSystemPath.h"
#import "TOFileSystemPresenter.h"

#import "NSURL+TOFileSystemUUID.h"
#import "NSFileManager+TOFileSystemDirectoryEnumerator.h"

@interface TOFileSystemItemList ()

/** The UUID string of the directory backing this object */
@property (nonatomic, copy, readwrite) NSString *uuid;

/** A weak reference to the observer object we were created by. */
@property (nonatomic, weak, readwrite) TOFileSystemObserver *fileSystemObserver;

/** A writeable copy of the location of this directory */
@property (nonatomic, strong, readwrite) NSURL *directoryURL;

/** Store a bookmark to this item in case the user moves it while it's open. */
@property (nonatomic, strong) NSData *bookmarkData;

/** An dictionary of the items in this dictionary, stored by their UUID. */
@property (nonatomic, strong) NSMutableDictionary<NSString *, TOFileSystemItem *> *items;

/** An array of the item UUIDs, sorted in the order specified. */
@property (nonatomic, strong) NSMutableArray<NSString *> *sortedItems;

@end

@implementation TOFileSystemItemList

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
                  fileSystemObserver:(TOFileSystemObserver *)observer
{
    if (self = [super init]) {
        _fileSystemObserver = observer;
        _directoryURL = directoryURL;
        _uuid = [directoryURL to_makeFileSystemUUIDIfNeeded];
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    // Create a bookmark object to let us track this URL if the user moves it
    _bookmarkData = [_directoryURL bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                            includingResourceValuesForKeys:nil
                                             relativeToURL:[TOFileSystemPath applicationSandboxURL]
                                                     error:nil];
    
    // Create the file list stores
    _items = [NSMutableDictionary dictionary];
    _sortedItems = [NSMutableArray array];
    
    // Build the initial item list
    [self buildItemsList];
}

- (void)buildItemsList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager to_fileSystemEnumeratorForDirectoryAtURL:_directoryURL];
    
    // Build a new list of files from what is currently on disk
    for (NSURL *url in enumerator) {
        TOFileSystemItem *item = [self.fileSystemObserver itemForFileAtURL:url];

        // Capture the item with its UUID in the dictionary
        _items[item.uuid] = item;
    }
    
    // Sort according to our current sort settings
    _sortedItems = _items.allKeys.mutableCopy;
    [self sortItemsList];
}

#pragma mark - Sorting Items -

- (void)sortItemsList
{
    // Sort all of the UUIDS
    [_sortedItems sortUsingComparator:^NSComparisonResult(NSString *firstUUID, NSString *secondUUID) {
        TOFileSystemItem *firstItem = _items[firstUUID];
        TOFileSystemItem *secondItem = _items[secondUUID];
        
        switch (_listOrder) {
            case TOFileSystemItemListOrderAlphanumeric:
                return [firstItem.name localizedStandardCompare:secondItem.name];
            case TOFileSystemItemListOrderDate:
                return [firstItem.modificationDate compare:secondItem.modificationDate];
            default:
                return firstItem.size > secondItem.size;
        }
    }];
    
    // If descending, flip the list
    if (self.isDescending) {
        _sortedItems = [[_sortedItems reverseObjectEnumerator] allObjects].mutableCopy;
    }
}

#pragma mark - External Item Access -

- (NSUInteger)count
{
    return self.items.count;
}

- (TOFileSystemItem *)objectAtIndex:(NSUInteger)index
{
    return self.items[self.sortedItems[index]];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return self.items[self.sortedItems[index]];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
    return [_items countByEnumeratingWithState:state
                                       objects:buffer
                                         count:len];
}

#pragma mark - Live Item Updating -

- (void)addItemWithUUID:(NSString *)uuid fileURL:(NSURL *)url
{
    
}

- (void)removeItemWithUUID:(NSString *)uuid fileURL:(NSURL *)url
{
    
}

- (void)itemDidRefresh:(TOFileSystemItem *)item
{
    
}

#pragma mark - Debugging -

- (NSString *)description
{
    return [NSString stringWithFormat:@"url = '%@', uuid = '%@', listOrder = %ld, isDescending = %d, items = '%@'",
            _directoryURL,
            _uuid,
            (long)_listOrder,
            _isDescending,
            _items];
}

@end
