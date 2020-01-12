//
//  TOFileSystemItemListChanges.h
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

/** State check to see if there are any pending movements. */
@property (nonatomic, readonly) BOOL hasItemMovements;

/** State check if it has cell updates that aren't movements. */
@property (nonatomic, readonly) BOOL hasItemChanges;

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
- (NSArray<NSIndexPath *> *)indexPathsForDeletionsInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths
 for items that were inserted. */
- (NSArray<NSIndexPath *> *)indexPathsForInsertionsInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths
 for items that were modified. */
- (NSArray<NSIndexPath *> *)indexPathsForModificationsInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths that
 items about to be moved were originally in. */
- (NSArray<NSIndexPath *> *)indexPathsForMovementSourcesInSection:(NSInteger)section;

/** For table/collection view convenience, create an array of index paths that
 items about to be moved are now currently in, based off an array of source index  */
- (NSArray<NSIndexPath *> *)indexPathsForMovementDestinationsWithSourceIndexPaths:(NSArray<NSIndexPath *> *)sourceIndexPaths;

@end

NS_ASSUME_NONNULL_END
