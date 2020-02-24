//
//  TOFileSystemPresenter.h
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

NS_ASSUME_NONNULL_BEGIN

/**
 This file presenter object handles coordinating state
 and events with the file system. It uses `NSFileCoordinator`
 to receive events from the system, when files change,
 and also performs coordinated reads and writes for retrieving
 UUIDs from the files it manages.
 */
@interface TOFileSystemPresenter : NSObject <NSFilePresenter>

/** The directory that will be observed by this presenter object */
@property (nonatomic, strong) NSURL *directoryURL;

/** The presenter is actively listening for events. */
@property (nonatomic, readonly) BOOL isRunning;

/**
 Since multiple events can come through, a timer is used to
 coalesce batches of events and trigger an update periodically.
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

/** Perform a synchronous coordinated read on a file. */
- (void)performCoordinatedRead:(void (^)(void))block;

/** Perform a synchronous write operation on a file */
- (void)performCoordinatedWrite:(void (^)(void))block;

/** Stop listening and cancel any pending timer events. */
- (void)stop;

/** Coordinates reading (and writing if need be) a UUID string for the supplied item */
- (nullable NSString *)uuidForItemAtURL:(NSURL *)itemURL;

@end

NS_ASSUME_NONNULL_END
