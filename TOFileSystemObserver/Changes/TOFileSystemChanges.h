//
//  TOFileSystemChanges.h
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

@class TOFileSystemItem;

NS_ASSUME_NONNULL_BEGIN

/**
 A list of items that have been detected
 to have changed in the file system.
 */
@interface TOFileSystemChanges : NSObject

/**
 A list of new items that have appeared in the file system
 since the last event.

 When a file is added from a Mac, it will initially be pending
 with the `isCopying` flag.
 */
@property (nonatomic, readonly) NSArray<TOFileSystemItem *> *addedItems;

/**
 A list of new items that have finished copying in since the last
 event.
*/
@property (nonatomic, readonly) NSArray<TOFileSystemItem *> *completedItems;

/**
 A list of items that have been moved since the last event,
 either moved to another directory, or simply renamed.

 The dictionary key is the previous file path of the
item
 */
@property (nonatomic, readonly) NSDictionary<NSURL *, TOFileSystemItem *> *movedItems;

/**
 A list of items that have been deleted.
 The array holds the previous file paths of the deleted items.
 */
@property (nonatomic, readonly) NSArray *deletedItems;

@end

NS_ASSUME_NONNULL_END
