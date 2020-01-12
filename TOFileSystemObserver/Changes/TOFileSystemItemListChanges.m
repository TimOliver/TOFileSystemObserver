//
//  TOFileSystemItemListChanges.m
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

- (BOOL)hasItemMovements
{
    return self.movements != nil;
}

- (BOOL)hasItemChanges
{
    return (self.deletions || self.insertions || self.modificatons);
}

@end
