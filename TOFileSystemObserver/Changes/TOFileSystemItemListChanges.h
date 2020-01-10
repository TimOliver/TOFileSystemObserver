//
//  TOFileSystemItemListChanges.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2020/01/10.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This class stores sets of indices denoting which objects,
 if any, in an item list were changed, and any subsequent user
 interfaces need to be refreshed.
 
 Whenever an item list detects a change has happened, it will
 trigger a notification block and provide an instance of this class.
 */
@interface TOFileSystemItemListChanges : NSObject

/** The indices of any objects that were deleted. */
@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *deletions;

/** The indices of any objects that were added. */
@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *insertions;

/** The indices of any objects that were modified. */
@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *modificatons;

/** The indices of any objects that have been moved in the list. */
@property (nonatomic, readonly, nullable) NSDictionary<NSNumber *, NSNumber *> *movements;

/** For table/collection view convenience, create an array of index paths
 for items that were deleted. */
- (nullable NSArray<NSIndexPath *> *)indexPathsForDeletionsInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths
 for items that were inserted. */
- (nullable NSArray<NSIndexPath *> *)indexPathsForInsertionsInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths
 for items that were modified. */
- (nullable NSArray<NSIndexPath *> *)indexPathsForModificationsInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths that
 items about to be moved were originally in. */
- (nullable NSArray<NSIndexPath *> *)indexPathsForMovementSourcesInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths that
 items about to be moved are now currently in, based off an array of source index  */
- (nullable NSArray<NSIndexPath *> *)indexPathsForMovementDestinationsWithSourceIndexPaths:(NSArray<NSIndexPath *> *)sourceIndexPaths;

@end

NS_ASSUME_NONNULL_END
