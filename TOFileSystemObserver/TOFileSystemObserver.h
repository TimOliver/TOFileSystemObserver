//
//  TOFileSystemObserver.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TOFileSystemItem.h"
#import "TOFileSystemBase.h"
#import "TOFileSystemNotificationToken.h"

@class TOFileSystemObserver;

typedef void (^TOFileSystemNotificationBlock)(TOFileSystemObserver * _Nonnull observer,
                                              TOFileSystemChanges * _Nullable changes);

NS_ASSUME_NONNULL_BEGIN

@interface TOFileSystemObserver : NSObject

/** Whether the observer is currently active and observing its target directory. */
@property (nonatomic, readonly) BOOL isRunning;

/**
 The absolute file path to the directory that will be observed.
 It may only be set while the observer isn't running. (Default is the Documents directory).
 */
@property (nonatomic, strong) NSURL *directoryURL;

/**
 Optionally, a list of relative file paths from `directoryURL` to directories that
 will not be monitored. By default, this includes the 'Inbox' directory in the
 Documents directory.
 */
@property (nonatomic, strong, nullable) NSArray<NSURL *> *excludedItems;

/**
 Optionally, the number of directoy levels down that the observer will recursively traverse from the base target.
 This is useful to avoid performance overhead in instances such as if your app only has one level of directories. (Default is 0).
 */
@property (nonatomic, assign) NSInteger includedDirectoryLevels;

/**
 The name of the snapshots database on disk.
 It may only be changed when the observer isn't running.
 The default value is "{AppBundleIdentifier}.fileSystemSnapshots.realm".
 */
@property (nonatomic, copy) NSString *databaseFileName;

/**
 The file route to the directory holding the snapshots database file on disk.
 It may only be changed when the observer isn't running.
 The default value is the application `Caches` directory. */
@property (nonatomic, copy) NSURL *databaseDirectoryURL;

/** A singleton instance that can be accessed globally. */
+ (instancetype)sharedObserver;

/** If desired, promotes a locally created and configured observer to the singleton. */
+ (instancetype)setSharedObserver:(TOFileSystemObserver *)observer;

/** Starts the file system observer monitoring the target directory for changes. */
- (void)start;

/** Suspends the file system observer from monitoring any file system changes. */
- (void)stop;

/** Deletes all of the data related to directory being monitored by this observer. */
- (void)reset;

/**
 Registers a new notification block that will be triggered each time an update is detected.
 It is your responsibility to strongly retain the token object, and release it only
 when you wish to stop receiving notifications.

 @param block A block that will be called each time a file system event is detected.
*/
- (TOFileSystemNotificationToken *)addNotificationBlock:(TOFileSystemNotificationBlock)block;

/**
 Registers a target object that will receive events when the file system changes.
 When an event occurs, the selector will be supplied with both a reference to this object,
 and a list of all the changes that occurred.

 @param target The object that will receive events.
 @param selector The selector that will be triggered when a change occurs.
 */
- (void)addTarget:(id)target forEventsWithSelector:(SEL)selector;

/**
 When not longer needed, de-registers an object that was receiving update events
 from the file system.

 @param target The object to cease sending events to.
 */
- (void)removeTarget:(id)target;

/**
 When the app itself is performing an operation to add a new item, this method
 can be used to disable the observer briefly while adding these items to
 avoid triggering a full scan in the process.

 @param itemURLs A list of all of the paths to the files that will be added.
 @param addAction Perfom the actual file add operations in this block. Scanning will be disabled for its duration.
 */
- (void)addItemsWithURLs:(NSArray<NSURL *> *)itemURLs addAction:(void (^)(void))addAction;

/**
When the app itself is performing an operation to more or rename an existing item, this method
can be used to disable the observer briefly while modifying these items to
avoid triggering a full scan in the process.

@param itemURLs A dictionary where the key is the old location, and the value is the new location of each item
@param moveAction Perfom the actual file move operations in this block. Scanning will be disabled for its duration.
*/
- (void)moveItemsWithURLs:(NSDictionary<NSURL *, NSURL *> *)itemURLs moveAction:(void (^)(void))moveAction;

/**
When the app itself is performing an operation to delete items, this method
can be used to disable the observer briefly while the deletion is in progress to
avoid triggering a full scan.

@param itemURLs A list of all of the paths to the files that will be added.
@param deleteAction Perfom the actual file move operations in this block. Scanning will be disabled for its duration.
*/
- (void)deleteItemsWithURLs:(NSArray<NSURL *> *)itemURLs moveAction:(void (^)(void))deleteAction;

@end

NS_ASSUME_NONNULL_END
