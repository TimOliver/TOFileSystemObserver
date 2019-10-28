//
//  TOFileSystemPresenter.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 27/10/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemPresenter.h"

@interface TOFileSystemPresenter ()

/** The presenter is actively listening for events. */
@property (nonatomic, assign, readwrite) BOOL isRunning;

/** The presenter is paused, so it will ignore any new events. */
@property (nonatomic, assign, readwrite) BOOL isPaused;

/** The operation queue that will receive all of the file events*/
@property (nonatomic, strong) NSOperationQueue *eventsOperationQueue;

/** The list of items currently detected. */
@property (nonatomic, strong) NSMutableArray *items;

/** A serial queue for managing access to the list (including the timer) */
@property (nonatomic, strong) dispatch_queue_t itemListAccessQueue;

/** A time object that will perform the batching of items when triggered */
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation TOFileSystemPresenter

#pragma mark - Class Lifecycle -

- (instancetype)init
{
    if (self = [super init]) {
        [self commongInit];
    }

    return self;
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
{
    if (self = [super init]) {
        _directoryURL = directoryURL;
        [self commongInit];
    }

    return self;
}

- (void)commongInit
{
    // Create the queue to receive events
    _eventsOperationQueue = [[NSOperationQueue alloc] init];
    _eventsOperationQueue.qualityOfService = NSQualityOfServiceBackground;

    // Create the array to hold the items detected
    _items = [NSMutableArray array];

    // Create the dispatch queue for the items
    _itemListAccessQueue = dispatch_queue_create("dev.tim.itemListAccessQueue", DISPATCH_QUEUE_SERIAL);

    // Default time interval
    _timerInterval = 0.1f;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark - Broadcast Items -

- (void)dispatchItemsToHandler
{
    // Un-set the timer so we can set a
    // new one on the next event
    self.timer = nil;

    // Get all of the items as an immutable copy
    NSArray *items = [NSArray arrayWithArray:self.items];

    // Empty the items list
    [self.items removeAllObjects];

    // Broadcast on the presenter queue the list of items
    if (self.itemsDidChangeHandler) {
        dispatch_async(self.eventsOperationQueue.underlyingQueue, ^{
            self.itemsDidChangeHandler(items);
        });
    };
}

#pragma mark - Timer Handling -

- (void)beginTimer
{
    // Synchronously fetch the timer object
    // to ensure we don't make two of them
    __block dispatch_source_t timer = nil;
    dispatch_sync(self.itemListAccessQueue, ^{
        timer = self.timer;
    });

    // Cancel out if we already are in progress
    if (timer) { return; }

    // Create a new timer
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                        self.eventsOperationQueue.underlyingQueue);

    // Set the timing
    uint64_t interval = self.timerInterval * (NSTimeInterval)1000000000;
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, 1000000000);

    // Set the event
    dispatch_source_set_event_handler(timer, ^{
        // On the item access queue, trigger an event occurring
        dispatch_async(self.itemListAccessQueue, ^{
            [self dispatchItemsToHandler];
        });
    });

    // Start the timer
    dispatch_resume(timer);

    // Save the timer
    dispatch_async(self.itemListAccessQueue, ^{
        self.timer = timer;
    });
}

- (void)cancelTimer
{
    __block dispatch_source_t timer = nil;
    dispatch_sync(self.itemListAccessQueue, ^{
        timer = self.timer;
        self.timer = nil;
    });

    dispatch_source_cancel(timer);
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
    if (self.isRunning && !self.isPaused) { return; }

    [NSFileCoordinator addFilePresenter:self];
    self.isRunning = YES;
    self.isPaused = NO;
}

- (void)pause
{
    if (!self.isRunning || self.isPaused) { return; }

    [NSFileCoordinator removeFilePresenter:self];
    self.isPaused = YES;
    self.isRunning = YES;
}

- (void)stop
{
    if (!self.isRunning) { return; }

    [NSFileCoordinator removeFilePresenter:self];
    self.isRunning = NO;
    self.isPaused = NO;

    // Cancel the timer
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
}

#pragma mark - NSFilePresenter Delegate Events -

- (void)presentedSubitemDidChangeAtURL:(NSURL *)url
{
    //NSLog(@"%@", url);
    //[self beginTimer];
    //[self addItemToList:url];
    NSLog(@"%@", url);
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
