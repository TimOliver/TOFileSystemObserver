//
//  TOFileSystemItemList+Private.h
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
#import "TOFileSystemItemList.h"
#import "TOFileSystemItem.h"
#import "TOFileSystemItemListChanges.h"

NS_ASSUME_NONNULL_BEGIN

@class TOFileSystemObserver;

/** Private interface for creating item objects */
@interface TOFileSystemItemList (Private)

/** Creates a new instance of an item for the target item. */
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
                  fileSystemObserver:(TOFileSystemObserver *)observer;

/** Add a new item to the list. */
- (void)addItemWithUUID:(NSString *)uuid itemURL:(NSURL *)url;

/** Triggered when an item's properties have changed. */
- (void)itemDidRefreshWithUUID:(NSString *)uuid;

/** Remove an object from the list (It was deleted or moved away). */
- (void)removeItemWithUUID:(NSString *)uuid fileURL:(NSURL *)url;

/** If the folder was moved, update it's own reference to its file path. */
- (BOOL)refreshWithURL:(nullable NSURL *)directoryURL;

/** Loop through every item on disk, and delete any items that are no longer there. */
- (void)synchronizeWithDisk;

@end

NS_ASSUME_NONNULL_END
