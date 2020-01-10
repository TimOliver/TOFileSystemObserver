//
//  TOFileSystemItemListChanges.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2020/01/10.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOFileSystemItemListChanges (Private)

/** Add the index of an item to be deleted. */
- (void)addDeletionIndex:(NSInteger)index;

/** Add the index of an item to be inserted. */
- (void)addInsertionIndex:(NSInteger)index;

/** Add the index of an item to be modified. */
- (void)addModificationIndex:(NSInteger)index;

/** Add the source and dest index values for a row to be moved. */
- (void)addMovementWithSourceIndex:(NSInteger)sourceIndex
                  destinationIndex:(NSInteger)destinationIndex;

@end

NS_ASSUME_NONNULL_END
