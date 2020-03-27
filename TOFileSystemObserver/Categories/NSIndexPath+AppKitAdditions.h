//
//  NSIndexPath+Additions.h
//  TOFileSystemObserverExample
//
//  Created by Anatoly Rosencrantz on 26/03/2020.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#if TARGET_OS_OSX

#import <Foundation/Foundation.h>
#import <AppKit/NSCollectionView.h>

@interface NSIndexPath(UIKitAdditions)
    -(NSInteger)row;
    +(NSIndexPath*)indexPathForRow:(NSInteger)row inSection:(NSInteger)section;
@end

#endif
