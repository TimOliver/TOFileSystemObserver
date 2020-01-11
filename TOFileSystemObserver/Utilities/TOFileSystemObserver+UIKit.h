//
//  TOFileSystemChangesUIKit.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2020/01/11.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

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
