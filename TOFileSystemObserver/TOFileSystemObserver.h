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

/** Deletes all of the data related to directory being monitored by this observer. */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
