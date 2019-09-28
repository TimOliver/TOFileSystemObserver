//
//  TOFileSystemChanges.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TOFileSystemItem;

NS_ASSUME_NONNULL_BEGIN

/**
 A list of items that have been detected
 to have changed in the file system.
 */
@interface TOFileSystemChanges : NSObject

/**
 A list of new items that have appeared in the file system
 since the last event.

 When a file is added from a Mac, it will initially be pending
 with the `isCopying` flag.
 */
@property (nonatomic, readonly) NSArray<TOFileSystemItem *> *addedItems;

/**
 A list of new items that have finished copying in since the last
 event.
*/
@property (nonatomic, readonly) NSArray<TOFileSystemItem *> *completedItems;

/**
 A list of items that have been moved since the last event,
 either moved to another directory, or simply renamed.

 The dictionary key is the previous file path of the
item
 */
@property (nonatomic, readonly) NSDictionary<NSURL *, TOFileSystemItem *> *movedItems;

/**
 A list of items that have been deleted.
 The array holds the previous file paths of the deleted items.
 */
@property (nonatomic, readonly) NSArray *deletedItems;

@end

NS_ASSUME_NONNULL_END
