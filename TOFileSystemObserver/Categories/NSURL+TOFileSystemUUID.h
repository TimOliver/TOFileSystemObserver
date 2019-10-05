//
//  NSURL+TOFileSystemUUID.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 30/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A convenience category that wraps the ability
 to assign a special extended attribute
 to the file, so we can uniquely track it.

 Thanks to NSHipster for highlighting this technique.
 https://nshipster.com/extended-file-attributes/
 */
@interface NSURL (TOFileSystemUUID)

/** Returns the unique UUID value assigned to this file, or creates a new one otherwise. */
- (nullable NSString *)to_fileSystemUUID;

/** Regardless of whether one exists or not, generates a new UUID for this item. */
- (NSString *)to_generateUUID;

@end

NS_ASSUME_NONNULL_END
