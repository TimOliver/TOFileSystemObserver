//
//  TOFileSystemSourceCollection.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 6/10/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The source collection object sets up,
 and stores references to all of the Dispatch
 Source objects used to track when the user
 makes a change in the file system
 */
@interface TOFileSystemSourceCollection : NSObject

/**
 A handler called whenever it is detected the
 contents of the particular item had changed.
 */
@property (nonatomic, copy) void (^itemChangedHandler)(NSString *uuid);

/**
 Create a new dispatch source off the directory
 at the provided URL.

 @param url The file URL to the target directory
 @param uuid The UUID representing this item
 */
- (void)addDirectoryAtURL:(NSURL *)url uuid:(NSString *)uuid;

/**
 Remove a directory from this collection

 @param uuid The UUID of the item to remove
 */
- (void)removeDirectoryWithUUID:(NSString *)uuid;

@end

NS_ASSUME_NONNULL_END
