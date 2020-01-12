//
//  TOFileSystemObserver.h
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
#import "TOFileSystemNotificationToken.h"
#import "TOFileSystemItemListChanges.h"

@class TOFileSystemObserver;

//typedef void (^TOFileSystemNotificationBlock)(TOFileSystemObserver * _Nonnull observer,
//                                              TOFileSystemChanges * _Nullable changes);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(FileSystemObserver)
@interface TOFileSystemObserver : NSObject

/** Whether the observer is currently active and observing its target directory. */
@property (nonatomic, readonly) BOOL isRunning;

/**
 The absolute file path to the directory that is being observed.
 It may only be set while the observer isn't running. (Default is the Documents directory).
 */
@property (nonatomic, strong) NSURL *directoryURL;

/**
 Optionally, a list of relative file paths from `directoryURL` to directories that
 will not be monitored. By default, this includes the 'Inbox' directory in the
 Documents directory.
 */
@property (nonatomic, strong, nullable) NSArray<NSString *> *excludedItems;

/**
 Optionally, the number of directoy levels down that the observer will recursively traverse from the base target.
 This is useful to avoid performance overhead in instances such as if your app only has one level of directories. (Default is 0).
 */
@property (nonatomic, assign) NSInteger includedDirectoryLevels;

/**
 The item that represents the base directory that was set to be observed
 by this file system observer.

 (This item will be refetched from the database each time it is called,
 so it is completely thread-safe. Like all Realm items, please ensure it
 is kept in an auto-release pool in dispatch queues.)
 */
@property (nonatomic, readonly) TOFileSystemItem *directoryItem;

/** Create a new instance of the observer with the base URL that will be observed. */
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL;

/** A singleton instance that can be accessed globally. It is created the first time this is called. */
+ (instancetype)sharedObserver;

/** If desired, promotes a locally created and configured observer to the singleton. */
+ (instancetype)setSharedObserver:(TOFileSystemObserver *)observer;

/** Starts the file system observer monitoring the target directory for changes. */
- (void)start;

/** Suspends the file system observer from monitoring any file system changes. */
- (void)stop;

/**
 Performs a full scan of the contents of the base directory on a background thread,
 and triggers all of the registered notification objects and blocks for
 every item discovered.
 
 Setting `includedDirectoryLevels` will limit how many directory levels down the scan
 will be performed, but by default, all levels are scanned.
 */
- (void)performFullDirectoryScan;

/**
 Returns a list of directories and files inside the directory specified.
 When the file observer is running, this list is live, and will be automatically
 updated whenever any of the underlying files on disk are changed.
 
 @param directoryURL The URL to target. Use `nil` for the observer's base directory.
 */
- (nullable TOFileSystemItemList *)itemListForDirectoryAtURL:(nullable NSURL *)directoryURL;

/**
 Returns an item object representing the file or directory at the URL specified.
 When the file observer is running, this object is live, and will be automatically
 updated whenever the system detects that the file has changed.
 
  @param fileURL The URL to target.
 */
- (nullable TOFileSystemItem *)itemForFileAtURL:(NSURL *)fileURL;

 /**
 Registers a new notification block that will be triggered each time an update is detected.
 It is your responsibility to strongly retain the token object, and release it only
 when you wish to stop receiving notifications.

 @param block A block that will be called each time a file system event is detected.
*/
//- (TOFileSystemNotificationToken *)addNotificationBlock:(TOFileSystemNotificationBlock)block;

@end

NS_ASSUME_NONNULL_END
