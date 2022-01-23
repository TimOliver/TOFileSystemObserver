//
//  TOFileSystemPresenter.m
//
//  Copyright 2019-2022 Timothy Oliver. All rights reserved.
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

#import "TOFileSystemPresenter.h"
#import "NSURL+TOFileSystemUUID.h"

@interface TOFileSystemPresenter ()

/** The presenter is actively listening for events. */
@property (nonatomic, assign, readwrite) BOOL isRunning;

/** The operation queue that will receive all of the file events*/
@property (nonatomic, strong) NSOperationQueue *eventsOperationQueue;

/** The list of items currently detected. */
@property (nonatomic, strong) NSMutableArray *items;

/** A serial queue for managing access to the list (including the timer) */
@property (nonatomic, strong) dispatch_queue_t itemListAccessQueue;

/** Whether a timer has been set yet or not */
@property (nonatomic, assign) BOOL isTiming;

/** A concurrent queue used to coordinate writing UUIDs to files. */
@property (nonatomic, readonly) dispatch_queue_t fileCoordinatorQueue;

@end

@implementation TOFileSystemPresenter

#pragma mark - Class Lifecycle -

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
{
    if (self = [super init]) {
        _directoryURL = directoryURL;
        [self commonInit];
    }

    return self;
}

- (dispatch_queue_t)fileCoordinatorQueue
{
    // In case we have multiple file observers, we must share this
    // coordinator amongst all of them in case two separate instances
    // try and write to the same file.
    static dispatch_queue_t _fileCoordinatorQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _fileCoordinatorQueue = dispatch_queue_create("TOFileSystemObserver.fileCoordinatorQueue",
                                                      DISPATCH_QUEUE_CONCURRENT);
    });
    return _fileCoordinatorQueue;
}

- (void)commonInit
{
    // Create the queue to receive events
    _eventsOperationQueue = [[NSOperationQueue alloc] init];
    _eventsOperationQueue.qualityOfService = NSQualityOfServiceBackground;

    // Create the array to hold the items detected
    _items = [NSMutableArray array];

    // Create the dispatch queue for the items
    _itemListAccessQueue = dispatch_queue_create("TOFileSystemObserver.itemListAccessQueue", DISPATCH_QUEUE_SERIAL);

    // Default time interval
    _timerInterval = 0.1f;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark - Timer Handling -

- (void)beginTimer
{
    // When the timer finishes, create a copy of the items,
    // and then flush what we currently have in the main item list
    id completionBlock = ^{
        if (!self.isRunning) { return; }
        self.isTiming = NO;

        @autoreleasepool {
            NSArray *items = [self.items copy];
            [self.items removeAllObjects];
            if (items.count == 0) { return; }

            if (self.itemsDidChangeHandler) {
                self.itemsDidChangeHandler(items);
            }
        }
    };

    id timerBlock = ^{
        // Cancel if timing has already been started
        if (self.isTiming) { return; }
        self.isTiming = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(self.timerInterval * NSEC_PER_SEC)),
                                      self.itemListAccessQueue,
                                      completionBlock);
    };

    dispatch_async(self.itemListAccessQueue, timerBlock);
}

#pragma mark - Item Handling -

- (void)addItemToList:(NSURL *)itemURL
{
    // Add the new item to the items list in a barrier queue access.
    dispatch_async(self.itemListAccessQueue, ^{
        [self.items addObject:itemURL];
    });
}

#pragma mark - Public Control -

- (void)start
{
    if (self.isRunning) { return; }
    [NSFileCoordinator addFilePresenter:self];
    self.isRunning = YES;
}

- (void)performCoordinatedRead:(void (^)(void))block
{
    dispatch_sync(self.fileCoordinatorQueue, ^{
        @autoreleasepool {
            if (block) { block(); }
        }
    });
}

- (void)performCoordinatedWrite:(void (^)(void))block
{
    dispatch_barrier_sync(self.fileCoordinatorQueue, ^{
        @autoreleasepool {
            if (block) { block(); }
        }
    });
}

- (void)stop
{
    if (!self.isRunning) { return; }
    [NSFileCoordinator removeFilePresenter:self];
    self.isRunning = NO;
}

- (nullable NSString *)uuidForItemAtURL:(NSURL *)itemURL
{
    __block NSString *uuid = nil;
    
    // If the file exists, but it's not in the store yet,
    // attempt to access it from disk
    [self performCoordinatedRead:^{
        uuid = [itemURL to_fileSystemUUID];
    }];
    if (uuid.length) { return uuid; }
    
    // If even that failed, then it's necessary to generate a new one
    [self performCoordinatedWrite:^{
        // Try again in case a previous operation already generated one
        uuid = [itemURL to_fileSystemUUID];
        if (uuid.length == 0) {
            uuid = [itemURL to_generateFileSystemUUID];
        }
    }];
    
    return uuid;
}

#pragma mark - NSFilePresenter Delegate Events -

- (void)presentedSubitemDidChangeAtURL:(NSURL *)url
{
    [self addItemToList:url];
    [self beginTimer];
}

- (NSURL *)presentedItemURL
{
    return self.directoryURL;
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    return self.eventsOperationQueue;
}

@end
