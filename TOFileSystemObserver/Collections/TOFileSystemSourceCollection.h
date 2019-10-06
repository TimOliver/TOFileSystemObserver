//
//  TOFileSystemSourceCollection.h
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
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
 Remove a directory from this collection.

 @param uuid The UUID of the item to remove
*/
- (void)removeDirectoryWithUUID:(NSString *)uuid;

/** Remove all Directories from observation. */
- (void)removeAllDirectories;

@end

NS_ASSUME_NONNULL_END
