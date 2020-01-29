//
//  TOFileSystemItem+Private.h
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
#import "TOFileSystemItem.h"

@class TOFileSystemObserver;

NS_ASSUME_NONNULL_BEGIN

/** Private interface for creating item objects */
@interface TOFileSystemItem ()

/** Creates a new instance of an item for the target item. */
- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL
                   fileSystemObserver:(TOFileSystemObserver *)observer;

/** Adds this item as a child of a list. */
- (void)addToList:(TOFileSystemItemList *)list;

/** Remove this item from a list. */
- (void)removeFromList;

/** Forces a refresh of the UUID (in cases where the file seems to have been duplicated) */
- (void)regenerateUUID;

/** Notify this object that it should re-fetch all its properties from disk.
    Returns true if there were changes. */
- (BOOL)refreshWithURL:(nullable NSURL *)itemURL;

@end

NS_ASSUME_NONNULL_END
