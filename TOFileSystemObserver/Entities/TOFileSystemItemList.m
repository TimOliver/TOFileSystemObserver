//
//  TOFileSystemList.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 10/11/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemItemList.h"
#import "TOFileSystemItem.h"
#import "TOFileSystemPath.h"
#import "TOFileSystemItem+Private.h"

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

/** The items array. Internally, it is mutable. */
@property (nonatomic, strong, readwrite) NSMutableArray<TOFileSystemItem *> *items;

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
    
    // Create the file list array
    _items = [NSMutableArray array];
    
    // Build the initial item list
    [self buildItemsList];
}

- (void)buildItemsList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager to_fileSystemEnumeratorForDirectoryAtURL:_directoryURL];
    
    // Build a new list of files from what is currently on disk
    for (NSURL *url in enumerator) {
        TOFileSystemItem *item = [[TOFileSystemItem alloc] initWithItemAtFileURL:url
                                                              fileSystemObserver:self.fileSystemObserver];
        [_items addObject:item];
    }
    
    // Sort according to our current sort settings
    [_items sortUsingDescriptors:@[self.currentSortingDescriptor]];
}

#pragma mark - Sorting Items -

- (NSSortDescriptor *)currentSortingDescriptor
{
    // Sorting alphanumeric
    if (self.listOrder == TOFileSystemItemListOrderAlphanumeric) {
        id sortingBlock = ^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 localizedStandardCompare:obj2];
        };
        return [NSSortDescriptor sortDescriptorWithKey:@"name"
                                             ascending:!self.isDescending
                                            comparator:sortingBlock];
    }
    
    NSString *sortingKey = nil;
    if (self.listOrder == TOFileSystemItemListOrderDate) {
        sortingKey = @"creationDate";
    }
    else {
        sortingKey = @"size";
    }
    
    return [NSSortDescriptor sortDescriptorWithKey:sortingKey ascending:!self.isDescending];
}

#pragma mark - External Item Access -

- (NSUInteger)count
{
    return self.items.count;
}

- (TOFileSystemItem *)objectAtIndex:(NSUInteger)index
{
    return _items[index];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
    return _items[index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
    return [_items countByEnumeratingWithState:state
                                       objects:buffer
                                         count:len];
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
