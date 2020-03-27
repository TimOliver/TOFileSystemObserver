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
