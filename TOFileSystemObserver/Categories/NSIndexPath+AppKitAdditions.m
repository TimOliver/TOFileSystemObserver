//
//  NSObject+NSIndexPath.m
//  TOFileSystemObserverExampleMac
//
//  Created by Anatoly Rosencrantz on 26/03/2020.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#if TARGET_OS_OSX

#import "NSIndexPath+AppKitAdditions.h"

@implementation NSIndexPath(UIKitAdditions)
    -(NSInteger)row {
        return self.item;
    }

    + (NSIndexPath *)indexPathForRow:(NSInteger)row inSection:(NSInteger)section {
        return [self indexPathForItem:row inSection:section];
    }
@end

#endif
