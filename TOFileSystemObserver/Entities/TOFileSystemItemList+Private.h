//
//  TOFileSystemItem+Private.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 12/11/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOFileSystemItemList.h"
#import "TOFileSystemItem.h"

@class TOFileSystemObserver;

/** Private interface for creating item objects */
@interface TOFileSystemItemList (Private)

/** Creates a new instance of an item for the target item. */
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
                  fileSystemObserver:(TOFileSystemObserver *)observer;

/** Add a new item to the list. */
- (void)addItemWithUUID:(NSString *)uuid fileURL:(NSURL *)url;

/** Triggered when an item's properties have changed. */
- (void)itemDidRefresh:(TOFileSystemItem *)item;

/** Remove an object from the list (It was deleted or moved away). */
- (void)removeItemWithUUID:(NSString *)uuid fileURL:(NSURL *)url;

@end
