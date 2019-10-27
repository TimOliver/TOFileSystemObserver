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

/** Local copy of the target directory URL */
@property (nonatomic, strong) NSURL *directoryURL;

/** The operation queue that will receive all of the file events*/
@property (nonatomic, strong) NSOperationQueue *eventsOperationQueue;

/** The list of items currently detected. */
@property (nonatomic, strong) NSMutableArray *items;

/** A dispatch queue to allow concurrent access to the stored list of items*/
@property (nonatomic, strong) dispatch_queue_t itemListAccessQueue;

@end

@implementation TOFileSystemPresenter

#pragma mark - Class Lifecycle -

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
{
    if (self = [super init]) {
        _directoryURL = directoryURL;

        // Create the queue to receive events
        self.eventsOperationQueue = [[NSOperationQueue alloc] init];
        self.eventsOperationQueue.qualityOfService = NSQualityOfServiceBackground;

        // Create the array to hold the items detected
        self.items = [NSMutableArray array];

        // Create the dispatch queue for the items
        self.itemListAccessQueue = dispatch_queue_create("dev.tim.itemListAccessQueue",
                                                         DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark - Item Handling -

- (void)addItemToList:(NSURL *)itemURL
{

}

- (NSArray *)allItemURLs
{
    return nil;
}

- (void)deleteAllItemsFromList
{

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
}

#pragma mark - NSFilePresenter Delegate Events -

- (void)presentedSubitemDidChangeAtURL:(NSURL *)url
{

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
