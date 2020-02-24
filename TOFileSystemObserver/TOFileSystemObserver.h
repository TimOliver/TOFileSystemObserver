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
#import "TOFileSystemChanges.h"
#import "TOFileSystemObserverConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class TOFileSystemObserver;

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

/**
 Turns on system-wide `NSNotification` broadcast events whenever a change is
 detected. This is YES for the singleton instance by default, but NO for all other instances.
 */
@property (nonatomic, assign) BOOL broadcastsNotifications;

/** Create a new instance of the observer with the base URL that will be observed. */
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL;

/** A singleton instance that can be accessed globally. It is created the first time this is called. */
+ (instancetype)sharedObserver;

/** If desired, promotes a locally created and configured observer to the singleton. */
+ (void)setSharedObserver:(TOFileSystemObserver *)observer;

/**
 Starts the file system observer monitoring the target directory for changes.
 Upon starting, the observer will perform a full file system scan, and will post a 'did discover'
 event for every item it finds. This can be used in order to ensure any caches, or previously
 expected locations of files can be updated.
 */
- (void)start;

/** Completely stops the file observer from running and resets all of the internal state. When
 calling 'start' from after this state, another full file system scan will be performed. */
- (void)stop;

/**
 Returns a list of directories and files inside the directory specified.
 While the file observer is running, this list is live, and will be automatically
 updated whenever any of the underlying files on disk are changed.
 
 @param directoryURL The URL to target. Use `nil` for the observer's base directory.
 */
- (nullable TOFileSystemItemList *)itemListForDirectoryAtURL:(nullable NSURL *)directoryURL;

/**
 Returns an item object representing the file or directory at the URL specified.
 While the file observer is running, this object is live, and will be automatically
 updated whenever the system detects that the file has changed.
 
  @param fileURL The URL to target.
 */
- (nullable TOFileSystemItem *)itemForFileAtURL:(NSURL *)fileURL;

/**
 Returns the unique UUID string that's been associated with the file at the provided URL from disk.
 This will attempt to retrieve the UUID while avoiding performing a file read if it can help it.
 If the file has not yet had a UUID string assigned, it will generate a new one in a thread-safe manner.
 
 @param itemURL The url of the item whose UUID that will be accessed.
 @return The UUID string associated with the file on disk. Returns nil if the URL is invalid.
 */
- (nullable NSString *)uuidForItemAtURL:(NSURL *)itemURL;

/**
 Returns the unique UUID for the parent directory of the item at the provided URL.
 This will attempt to retrieve the UUID while avoiding performing a file read if it can help it.
 If the item doesn't yet have a UUID, it will create one in a thread safe manner.
 */
- (nullable NSString *)uuidForParentOfItemAtURL:(NSURL *)itemURL;

 /**
 Registers a new notification block that will be triggered each time an update is detected.
 It is your responsibility to strongly retain the token object, and release it only
 when you wish to stop receiving notifications.

 @param block A block that will be called each time a file system event is detected.
*/
- (TOFileSystemNotificationToken *)addNotificationBlock:(TOFileSystemNotificationBlock)block;

/**
 When a notification token is no longer needed, it can be removed from the observer
 and freed from memory. This method will automatically be called if `invalidate` is
 called from the token.
 
 @param token The token that will be removed from the observer and deallocated.
 */
- (void)removeNotificationToken:(TOFileSystemNotificationToken *)token;

@end

FOUNDATION_EXPORT double TOFileSystemObserverVersionNumber;
FOUNDATION_EXPORT const unsigned char TOFileSystemObserverVersionString[];

NS_ASSUME_NONNULL_END
