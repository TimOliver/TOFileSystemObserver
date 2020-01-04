//
//  TOFileSystemItemDictionary.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2019/12/27.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A thread-safe dictionary that stores the file paths
 to items using their on-disk UUID string as the key.
 
 This is used to store an in-memory graph of all of the files
 as they were at the start of the app session, so that any
 detected changes to the file system can be compared.
 */
@interface TOFileSystemItemDictionary : NSObject

/** The number of items currently in the dictionary. */
@property (nonatomic, readonly) NSUInteger count;

/** Create a new instance with the base URL that all items will be relatively saved against. */
- (instancetype)initWithBaseURL:(NSURL *)baseURL;

/** Adds an item URL to the dictionary. May be called from multiple threads. */
- (void)setItemURL:(nullable NSURL *)itemURL forUUID:(nullable NSString *)uuid;

/** Retrieves an item URL from the dictionary. May be called from multiple threads. */
- (nullable NSURL *)itemURLForUUID:(nullable NSString *)uuid;

/** Tries to retrieve a UUID value for a URL, if it exists */
- (nullable NSString *)uuidForItemWithURL:(NSURL *)itemURL;

/** Implementations for allowing dictionary style literal syntax. */
- (void)setObject:(nullable id)object forKeyedSubscript:(nonnull NSString *)key;
- (nullable id)objectForKeyedSubscript:(NSString *)key;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
