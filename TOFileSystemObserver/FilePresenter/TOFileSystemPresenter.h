//
//  TOFileSystemPresenter.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 27/10/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This file presenter object works in conjunction
 with the system `NSFileCoordinator` object to receive
 events whenever any of the sub-directories or files inside
 the base directory change.
 */
@interface TOFileSystemPresenter : NSObject <NSFilePresenter>

/** The directory that will be observed by this presenter object */
@property (nonatomic, strong) NSURL *directoryURL;

/** The presenter is actively listening for events. */
@property (nonatomic, readonly) BOOL isRunning;

/**
 Since multiple events can come through, a timer is used to
 coalesce batchs of events and trigger an update periodically.
 (Default is 100 miliseconds)
*/
@property (nonatomic, assign) NSTimeInterval timerInterval;

/**
 A block that will be called with all of the collected events.
 It will be called on the same operation queue as managed by this class,
 so the logic contained should be thread-safe.
*/
@property (nonatomic, copy) void (^itemsDidChangeHandler)(NSArray<NSURL *> *itemURLs);

/** Start listening for file events in the target directory. */
- (void)start;

/** Pause listening, execute the provided block, and then resume. */
- (void)pauseWhileExecutingBlock:(void (^)(void))block;

/** Stop listening and cancel any pending timer events. */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
