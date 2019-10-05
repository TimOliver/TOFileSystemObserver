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

/** A unique identifier we can use to ensure this object is unique */
@property (nonatomic, strong) NSString *uuid;

/** From the top of the app sandbox, the path to the directory we are targeting. */
@property (nonatomic, copy) NSString *filePath;

/** The subsequent item representing the directory we are targeting. */
@property (nonatomic, strong) TOFileSystemItem *item;

/** If an object already exists in realm, it returns the existing object, else it creates a new one */
+ (instancetype)baseObjectInRealm:(RLMRealm *)realm forItemAtFileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
