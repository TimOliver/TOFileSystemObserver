//
//  TOFileSystemItemDictionary.h
//
//  Copyright 2019-2020 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A thread-safe dictionary that stores the file paths
 to items using their on-disk UUID string as the key.
 
 This is used to store an in-memory graph of all of the files
 as they were at the start of the app session, so that any
 detected changes to the file system can be compared.
 */
@interface TOFileSystemItemURLDictionary : NSObject

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

/** Delete an entry from the store. */
- (void)removeItemURLForUUID:(NSString *)uuid;

/** Implementations for allowing dictionary style literal syntax. */
- (void)setObject:(nullable id)object forKeyedSubscript:(nonnull NSString *)key;
- (nullable id)objectForKeyedSubscript:(NSString *)key;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
