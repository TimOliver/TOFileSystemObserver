//
//  TOFileSystemBase.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "RLMObject.h"

#import "TOFileSystemItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The base item is the entry point for observing a
 directory. It stores the absolute path to our target
 directory in the app sandbox, and holds the array
 graph of all of the items we are observing.
 */
@interface TOFileSystemBase : RLMObject

/** From the top of the app sandbox, the path to the directory containing our target. */
@property (nonatomic, copy) NSString *filePath;

/** The graph of all observed objects, starting with the target directory. */
@property (nonatomic, strong) RLMArray<TOFileSystemItem *><TOFileSystemItem> *items;

@end

NS_ASSUME_NONNULL_END
