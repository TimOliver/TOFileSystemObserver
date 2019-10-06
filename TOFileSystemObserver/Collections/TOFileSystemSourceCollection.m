//
//  TOFileSystemSourceCollection.m
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
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

#import "TOFileSystemSourceCollection.h"

@interface TOFileSystemSourceCollection ()

/** A dictionary to retain all of the dispatch sources. */
@property (nonatomic, strong) NSMutableDictionary<NSString *, dispatch_source_t> *sourcesDictionary;

/** A queue to allow thread safe reads and writes to the dictionary. */
@property (nonatomic, copy) dispatch_queue_t sourcesBarrierQueue;

@end

@implementation TOFileSystemSourceCollection

#pragma mark - Class Lifecycle -

- (instancetype)init
{
    if (self = [super init]) {
        _sourcesBarrierQueue = dispatch_queue_create("dev.tim.sourcesDispatchQueue", DISPATCH_QUEUE_CONCURRENT);
        _sourcesDictionary = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)dealloc
{
    [self removeAllDispatchSources];
}

#pragma mark - Public Interface -

- (void)addDirectoryAtURL:(NSURL *)url uuid:(NSString *)uuid
{
    // Make sure we didn't already set an observer
    if ([self dispatchSourceForUUID:uuid] != nil) { return; }

    // Set up the dispatch source observer
    dispatch_source_t source = [self makeDispatchSourceForItemAtURL:url uuid:uuid];

    // Add it to our dictionary
    [self setDispatchSource:source forUUID:uuid];
}

- (void)removeDirectoryWithUUID:(NSString *)uuid
{
    [self removeDispatchSourceForUUID:uuid];
}

- (void)removeAllDirectories
{
    [self removeAllDispatchSources];
}

#pragma mark - Internal -

- (void)didObserverChangeForItemWithUUID:(NSString *)uuid
{
    // Trigger the block
    if (self.itemChangedHandler) {
        self.itemChangedHandler(uuid);
    }
}

- (dispatch_source_t)makeDispatchSourceForItemAtURL:(NSURL *)url uuid:(NSString *)uuid
{
    // Get our target directory handle
    int fd = open(url.path.UTF8String, O_EVTONLY);
    if (fd == -1) { return nil; }

    // Get the lowest priority queue to work on
    dispatch_queue_t queue = dispatch_get_main_queue(); //dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                              fd,
                                                              DISPATCH_VNODE_WRITE,
                                                              queue);
    if (dispatchSource == NULL) { return nil; }

    // Set the event handler
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(dispatchSource, ^{
        [weakSelf didObserverChangeForItemWithUUID:uuid];
    });

    // Set a cancel handler
    dispatch_source_set_cancel_handler(dispatchSource, ^{
        close(fd);
    });

    // Start observing
    dispatch_resume(dispatchSource);

    // Return the source
    return dispatchSource;
}

- (dispatch_source_t)dispatchSourceForUUID:(NSString *)uuid
{
    if (uuid.length == 0) { return nil; }

    __block dispatch_source_t source = nil;
    dispatch_sync(_sourcesBarrierQueue, ^{
        source = self.sourcesDictionary[uuid];
    });
    return source;
}

- (void)setDispatchSource:(dispatch_source_t)source forUUID:(NSString *)uuid
{
    if (uuid.length == 0) { return; }

    dispatch_barrier_async(self.sourcesBarrierQueue, ^{
        self.sourcesDictionary[uuid] = source;
    });
}

- (void)removeDispatchSourceForUUID:(NSString *)uuid
{
    if (uuid.length == 0) { return; }

    // Fetch the source
    dispatch_source_t source = [self dispatchSourceForUUID:uuid];

    // Cancel the source, and remove from the dictionary
    dispatch_barrier_async(self.sourcesBarrierQueue, ^{
        dispatch_cancel(source);
        [self.sourcesDictionary removeObjectForKey:uuid];
    });
}

- (void)removeAllDispatchSources
{
    // Get all of the sources from the array
    __block NSArray *sources = nil;
    dispatch_sync(self.sourcesBarrierQueue, ^{
        sources = self.sourcesDictionary.allValues;
    });

    // Loop through and cancel every source, and remove
    dispatch_barrier_async(self.sourcesBarrierQueue, ^{
        for (dispatch_source_t source in sources) {
            dispatch_cancel(source);
        }

        [self.sourcesDictionary removeAllObjects];
    });
}

@end
