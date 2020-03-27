//
//  TOFileSystemItem.h
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

#import "TOFileSystemObserverConstants.h"

@class TOFileSystemObserver;
@class TOFileSystemItemList;

NS_ASSUME_NONNULL_BEGIN

/**
 An object that represents either a file
 or folder on disk.
 */
NS_SWIFT_NAME(FileSystemItem)
@interface TOFileSystemItem : NSObject

/** The absolute URL path to this item. */
@property (nonatomic, readonly) NSURL *fileURL;

/** The type of the item (either a file or folder) */
@property (nonatomic, readonly) TOFileSystemItemType type;

/** The unique UUID that was assigned to the file by this library. */
@property (nonatomic, readonly) NSString *uuid;

/** The name on disk of the item. */
@property (nonatomic, readonly) NSString *name;

/** The size (in bytes) of this item. (0 for directories). */
@property (nonatomic, readonly) long long size;

/** The creation date of the item. */
@property (nonatomic, readonly) NSDate *creationDate;

/** The last modification date of the item. */
@property (nonatomic, readonly) NSDate *modificationDate;

/** If a directory, the number of files/subdirectories inside this item. */
@property (nonatomic, readonly) NSInteger numberOfSubItems;

/** Whether the item is still being copied into the app container. */
@property (nonatomic, readonly) BOOL isCopying;

/** Whether the item on disk represented by this object no longer exists. */
@property (nonatomic, readonly) BOOL isDeleted;

/** The file system observer backing this object. */
@property (nonatomic, weak, readonly) TOFileSystemObserver *fileSystemObserver;

/** Returns the list this item belongs to (if a list has separately been created.) */
@property (nonatomic, weak, nullable, readonly) TOFileSystemItemList *list;

@end

NS_ASSUME_NONNULL_END
