//
//  TOFileSystemObserver+UIKit.h
//
//  Copyright 2019-2022 Anatoly Rosencrantz, Timothy Oliver. All rights reserved.
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

//
//  TOFileSystemObserver+UIKit.h
//  TOFileSystemObserverMacExample
//
//  Created by Anatoly Rosencrantz on 26/03/2020.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#if TARGET_OS_OSX

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "TOFileSystemItemListChanges.h"

/// A convenience function to update a standard `NSTableView` with a new set
/// of changes reported by a file system observer.
/// @param tableView The `NSTableView` to update
/// @param changes The changes that were returned from the file system obserrver.
/// @param section The section in the table view that the changes should be applied to.
static inline void TOFileSystemItemListUpdateTableView(NSTableView * _Nonnull tableView,
                                                TOFileSystemItemListChanges * _Nonnull changes,
                                                NSInteger section)
{
    // Perform any cell re-ordering in its own batch operation first
    if (changes.hasItemMovements) {
        [tableView beginUpdates];
        {
            NSArray<NSIndexPath *> *sourceMovements = [changes indexPathsForMovementSourcesInSection:section];
            NSArray<NSIndexPath *> *destinationMovements = [changes indexPathsForMovementDestinationsWithSourceIndexPaths:sourceMovements];
            for (NSInteger i = 0; i < sourceMovements.count; i++) {
                [tableView moveRowAtIndex:sourceMovements[i].item toIndex:destinationMovements[i].item];
            }
        }
        [tableView endUpdates];
    }
    
    // Perform all additional cell update operations afterwards
    if (changes.hasItemChanges) {
        [tableView beginUpdates];
        {
            NSMutableIndexSet *changesList = [[NSMutableIndexSet alloc] init];
            [[changes indexPathsForDeletionsInSection:section] enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [changesList addIndex:(NSUInteger)obj.item];
            }];
            [tableView removeRowsAtIndexes:changesList withAnimation:NSTableViewAnimationEffectFade];
            
            NSMutableIndexSet *insertsList = [[NSMutableIndexSet alloc] init];
            [[changes indexPathsForInsertionsInSection:section] enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [insertsList addIndex:(NSUInteger)obj.item];
            }];
            [tableView insertRowsAtIndexes:insertsList withAnimation:NSTableViewAnimationEffectFade];
            
            NSMutableIndexSet *reloadsList = [[NSMutableIndexSet alloc] init];
            [[changes indexPathsForModificationsInSection:section] enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [reloadsList addIndex:(NSUInteger)obj.item];
            }];
            [tableView reloadDataForRowIndexes:reloadsList columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        }
        [tableView endUpdates];
    }
}

#endif
