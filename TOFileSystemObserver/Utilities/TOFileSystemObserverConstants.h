//
//  TOFileSystemObserverConstants.h
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

@class TOFileSystemObserver;
@class TOFileSystemChanges;
@class TOFileSystemItemList;
@class TOFileSystemItemListChanges;

NS_ASSUME_NONNULL_BEGIN

/** When calling a notification block, these are the types of events available. */
typedef NS_ENUM(NSInteger, TOFileSystemObserverNotificationType) {
    TOFileSystemObserverNotificationTypeDidChange,          // The scanner detected a file change
    TOFileSystemObserverNotificationTypeWillBeginFullScan,  // The scanner is about to perform a full-scan
    TOFileSystemObserverNotificationTypeDidCompleteFullScan // The scanner just completed a full scan
} NS_SWIFT_NAME(FileSystemObserver.NotificationType);

/** The different options for ordering item lists */
typedef NS_ENUM(NSInteger, TOFileSystemItemListOrder) {
    TOFileSystemItemListOrderAlphanumeric,  // Alphanumeric ordering
    TOFileSystemItemListOrderDate,          // Creation date
    TOFileSystemItemListOrderSize           // File size
} NS_SWIFT_NAME(FileSystemItemList.Order);

// The different types of items stored in the file system
typedef NS_ENUM(NSInteger, TOFileSystemItemType) {
    TOFileSystemItemTypeFile, // A standard file
    TOFileSystemItemTypeDirectory // A folder
} NS_SWIFT_NAME(FileSystemItem.Type);

/** Whenever a scan event occurs, all registered notification blocks will be called with the change information. */
typedef void (^TOFileSystemNotificationBlock)(TOFileSystemObserver * _Nonnull observer,
                                              TOFileSystemObserverNotificationType type,
                                               TOFileSystemChanges * _Nullable changes)
                                                NS_SWIFT_NAME(FileSystemNotificationBlock);

/** A block that may be registered in order to observe when items in the list change. */
typedef void (^TOFileSystemItemListNotificationBlock)(TOFileSystemItemList * _Nonnull itemList,
                                                      TOFileSystemItemListChanges * _Nullable changes)
                                                        NS_SWIFT_NAME(FileSystemItemListNotificationBlock);

/**
 A notification that will be broadcast before a full file system scan starts.
 It will be called on the same thread as the scan operation.
 */
extern NSNotificationName const TOFileSystemObserverWillBeginFullScanNotification
                                    NS_SWIFT_NAME(FileSystemObserverWillBeginFullScanNotification);

/**
 A notification that will be broadcast once a full scan has completed.
 It will be called on the same thread as the scan operation.
 */
extern NSNotificationName const TOFileSystemObserverDidCompleteFullScanNotification
                                    NS_SWIFT_NAME(FileSystemObserverWillDidCompleteScanNotification);

/**
 A notification that will be broadcast when a file change was observed.
 
 It will be called on the same thread as the scan operation.
*/
extern NSNotificationName const TOFileSystemObserverDidChangeNotification
                                    NS_SWIFT_NAME(FileSystemObserverDidChangeNotification);

/**
 When a notification is broadcasted from an observer, a reference to that
 observer object will be included in `userInfo` under this key.
 */
extern NSString * const TOFileSystemObserverUserInfoKey
                                NS_SWIFT_NAME(FileSystemObserverUserInfoKey);

/**
 When a notification is broadcasted, all of the changes that were detected
 will be provided in the notification `userInfo` dictionary under this key.
 */
extern NSString * const TOFileSystemObserverChangesUserInfoKey
                                NS_SWIFT_NAME(FileSystemObserverChangesUserInfoKey);

NS_ASSUME_NONNULL_END
