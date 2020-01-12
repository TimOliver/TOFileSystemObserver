//
//  TOFileSystemObserver+UIKit.h
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
#import <UIKit/UIKit.h>
#import "TOFileSystemItemListChanges.h"

/**
 These convenience functions will perform the default
 update behaviour whenever an item on the file system changes.
 */
static inline void TOFileSystemItemListUpdateTableView(UITableView * _Nonnull tableView,
                                                TOFileSystemItemListChanges * _Nonnull changes,
                                                NSInteger section)
{
    // Perform any cell re-ordering in its own batch operation first
    if (changes.hasItemMovements) {
        [tableView beginUpdates];
        {
            NSArray *sourceMovements = [changes indexPathsForMovementSourcesInSection:section];
            NSArray *destinationMovements = [changes indexPathsForMovementDestinationsWithSourceIndexPaths:sourceMovements];
            for (NSInteger i = 0; i < sourceMovements.count; i++) {
                [tableView moveRowAtIndexPath:sourceMovements[i] toIndexPath:destinationMovements[i]];
            }
        }
        [tableView endUpdates];
    }
    
    // Perform all additional cell update operations afterwards
    if (changes.hasItemChanges) {
        [tableView beginUpdates];
        {
            [tableView deleteRowsAtIndexPaths:[changes indexPathsForDeletionsInSection:section]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:[changes indexPathsForInsertionsInSection:section]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView reloadRowsAtIndexPaths:[changes indexPathsForModificationsInSection:section]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [tableView endUpdates];
    }
}

static inline void TOFileSystemItemListUpdateCollectionView(UICollectionView * _Nonnull collectionView,
                                                     TOFileSystemItemListChanges * _Nonnull changes,
                                                     NSInteger section)
{
    // Perform any cell re-ordering in its own batch operation first
    [collectionView performBatchUpdates:^{
        NSArray *sourceMovements = [changes indexPathsForMovementSourcesInSection:section];
        NSArray *destinationMovements = [changes indexPathsForMovementDestinationsWithSourceIndexPaths:sourceMovements];
        for (NSInteger i = 0; i < sourceMovements.count; i++) {
            [collectionView moveItemAtIndexPath:sourceMovements[i] toIndexPath:destinationMovements[i]];
        }
    } completion:nil];
    
    // Perform all additional cell update operations afterwards
    [collectionView performBatchUpdates:^{
        [collectionView deleteItemsAtIndexPaths:[changes indexPathsForDeletionsInSection:section]];
        [collectionView insertItemsAtIndexPaths:[changes indexPathsForInsertionsInSection:section]];
        [collectionView reloadItemsAtIndexPaths:[changes indexPathsForModificationsInSection:section]];
    } completion:nil];
}
