//
//  TOFileSystemList.h
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

@class TOFileSystemObserver;
@class TOFileSystemItem;
@class TOFileSystemItemListChanges;
@class TOFileSystemNotificationToken;
@class TOFileSystemItemList;

/** A block that may be registered in order to observe when items in the list change. */
typedef void (^TOFileSystemItemListNotificationBlock)(TOFileSystemItemList * _Nonnull itemList,
                                                      TOFileSystemItemListChanges * _Nullable changes);

/** The different options for ordering item lists */
typedef NS_ENUM(NSInteger, TOFileSystemItemListOrder) {
    TOFileSystemItemListOrderAlphanumeric,  // Alphanumeric ordering
    TOFileSystemItemListOrderDate,          // Creation date
    TOFileSystemItemListOrderSize           // File size
};

NS_ASSUME_NONNULL_BEGIN

/**
 This class represents a list of files and
 directories located within the directroy that was
 specified.
 
 It is backed by an observer object, that will ensure
 that it is kept up-to-date with any changes that occur on
 the file system.
 */
@interface TOFileSystemItemList : NSObject<NSFastEnumeration>

/** The unique UUID string saved in the attributes of this directory. */
@property (nonatomic, readonly) NSString *uuid;

/** The observer object backing this list object. */
@property (nonatomic, weak, readonly) TOFileSystemObserver *fileSystemObserver;

/** The type of ordering of the items. */
@property (nonatomic, assign) TOFileSystemItemListOrder listOrder;

/** Whether the list is ascending or descending. (Default is ascending). */
@property (nonatomic, assign) BOOL isDescending;

/** The number of items in this list. */
@property (nonatomic, readonly) NSUInteger count;

/** The absolute URL to this directory containing these items. */
@property (nonatomic, readonly) NSURL *directoryURL;

/**
 Registers a new notification block that will be
 triggered each time the data in the list changes.
 
 The returned notification token must be strongly retained
 by your code for the duration you wish to receive notifications.
 */
- (TOFileSystemNotificationToken *)addNotificationBlock:(TOFileSystemItemListNotificationBlock)block;

/** Retrieves the item at the requested index. */
- (TOFileSystemItem *)objectAtIndex:(NSUInteger)index;

/** Allows array-style lookup of items at specific indexes. */
- (TOFileSystemItem *)objectAtIndexedSubscript:(NSUInteger)index;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
