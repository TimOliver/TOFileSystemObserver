//
//  TOFileSystemItemListChanges.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2020/01/10.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import "TOFileSystemItemListChanges.h"
#import <UIKit/NSIndexPath+UIKitAdditions.h>

@interface TOFileSystemItemListChanges ()

/** The indices of any objects that were deleted. */
@property (nonatomic, strong, readwrite) NSMutableArray<NSNumber *> *deletions;

/** The indices of any objects that were added. */
@property (nonatomic, strong, readwrite) NSMutableArray<NSNumber *> *insertions;

/** The indices of any objects that were modified. */
@property (nonatomic, strong, readwrite) NSMutableArray<NSNumber *> *modificatons;

/** The indices of any objects that have been moved in the list. */
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSNumber *, NSNumber *> *movements;

@end

@implementation TOFileSystemItemListChanges

#pragma mark - Adding Index Values -

- (void)addDeletionIndex:(NSInteger)index
{
    if (self.deletions == nil) {
        self.deletions = [NSMutableArray array];
    }
    
    [(NSMutableArray *)self.deletions addObject:@(index)];
}

- (void)addInsertionIndex:(NSInteger)index
{
    if (self.insertions == nil) {
        self.insertions = [NSMutableArray array];
    }
    
    [(NSMutableArray *)self.insertions addObject:@(index)];
}

- (void)addModificationIndex:(NSInteger)index
{
    if (self.modificatons == nil) {
        self.modificatons = [NSMutableArray array];
    }
    
    [(NSMutableArray *)self.modificatons addObject:@(index)];
}

- (void)addMovementWithSourceIndex:(NSInteger)sourceIndex
                  destinationIndex:(NSInteger)destinationIndex
{
    if (self.movements == nil) {
        self.movements = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *dict = (NSMutableDictionary *)self.movements;
    dict[@(sourceIndex)] = @(destinationIndex);
}

#pragma mark - Table/Collection View Converters -

- (NSArray<NSIndexPath *> *)indexPathsForCollection:(nullable NSArray<NSNumber *> *)collection
                                                   inSection:(NSInteger)section
{
    if (!collection) { return [NSArray array]; }
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSNumber *number in collection) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:number.intValue inSection:section];
        [array addObject:indexPath];
    }
    
    return [NSArray arrayWithArray:array];
}

- (NSArray<NSIndexPath *> *)indexPathsForDeletionsInSection:(NSInteger)section
{
    return [self indexPathsForCollection:self.deletions inSection:section];
}

- (NSArray<NSIndexPath *> *)indexPathsForInsertionsInSection:(NSInteger)section
{
    return [self indexPathsForCollection:self.insertions inSection:section];
}

- (NSArray<NSIndexPath *> *)indexPathsForModificationsInSection:(NSInteger)section
{
    return [self indexPathsForCollection:self.modificatons inSection:section];
}

- (NSArray<NSIndexPath *> *)indexPathsForMovementSourcesInSection:(NSInteger)section
{
    return [self indexPathsForCollection:self.movements.allKeys inSection:section];
}

- (NSArray<NSIndexPath *> *)indexPathsForMovementDestinationsWithSourceIndexPaths:(NSArray<NSIndexPath *> *)sourceIndexPaths
{
    if (self.movements == nil) { return [NSArray array]; }
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSIndexPath *sourceIndexPath in sourceIndexPaths) {
        NSInteger row = self.movements[@(sourceIndexPath.row)].intValue;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
        [array addObject:indexPath];
    }
    
    return [NSArray arrayWithArray:array];
}

@end
