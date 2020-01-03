//
//  TOFileSystemItem+Private.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 12/11/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOFileSystemItem.h"

@class TOFileSystemObserver;

/** Private interface for creating item objects */
@interface TOFileSystemItem (Private)

/** Creates a new instance of an item for the target item. */
- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL
                   fileSystemObserver:(TOFileSystemObserver *)observer;

/** Forces a refresh of the UUID (in cases where the file seems to have been duplicated) */
- (void)regenerateUUID;

@end
