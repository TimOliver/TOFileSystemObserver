//
//  TOFileSystemObserver.m
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

#import "TOFileSystemObserver.h"

#import "TOFileSystemPath.h"
#import "TOFileSystemRealmConfiguration.h"
#import "TOFileSystemScanOperation.h"

@interface TOFileSystemObserver()

/** Read-write access for the running state */
@property (nonatomic, assign, readwrite) BOOL isRunning;

/** Temporarily skip an event if we're explicitly touching the file system. */
@property (nonatomic, assign) BOOL skipEvents;

/** The dispatch sources in charge of all directories we are observing. */
@property (nonatomic, strong) NSDictionary<NSString *, dispatch_source_t> *dispatchSources;

/** A barrier queue to ensure thread-safe access to the sources dictionary */
@property (nonatomic, copy) dispatch_queue_t sourcesBarrierQueue;

/** The operation queue we will perform our scanning on. */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/** The configuration for the Realm database we'll be using. */
@property (nonatomic, strong) RLMRealmConfiguration *realmConfiguration;

/** Gets a new copy of the Realm database backing this observer. */
@property (nonatomic, readonly) RLMRealm *realm;

/** Gets the base object from Realm, or creates it on the first time. */
@property (nonatomic, readonly) TOFileSystemBase *baseObject;

@end

@implementation TOFileSystemObserver

#pragma mark - Object Lifecycle -

- (instancetype)init
{
    if (self = [super init]) {
        [self setUp];
    }

    return self;
}

- (void)setUp
{
    // Set-up default property values
    _isRunning = NO;
    _excludedItems = @[@"Inbox"];
    _targetDirectoryURL = [TOFileSystemPath documentsDirectoryURL];
    _databaseFileName = [TOFileSystemPath defaultDatabaseFileName];
    _databaseDirectoryURL = [TOFileSystemPath cachesDirectoryURL];
    _dispatchSources = [NSDictionary dictionary];

    // Set-up the operation queue
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    _operationQueue.qualityOfService = NSQualityOfServiceBackground;
}

#pragma mark - Observer Setup -

- (BOOL)configureDatabase
{
    // Create the Realm configuration
    NSURL *databaseFileURL = [self.databaseDirectoryURL
                                URLByAppendingPathComponent:self.databaseFileName];
    self.realmConfiguration = [TOFileSystemRealmConfiguration
                               fileSystemConfigurationWithFileURL:databaseFileURL];

    // Remove the database while we're developing
    [[NSFileManager defaultManager] removeItemAtURL:self.realmConfiguration.fileURL error:nil];

    // Try creating the database for potentially the first time
    if (self.realm == nil) { return NO; }

    // Then try creating the base object for our taget folder for the first time
    return (self.baseObject != nil);
}

#pragma mark - Observer Lifecycle -

- (void)start
{
    if (self.isRunning) { return; }

    // Set the running state
    self.isRunning = YES;

    // Set up and configure our backing data store
    if (![self configureDatabase]) {
        [self stop];
        return;
    }

    // Perform the first full-length initial scan
    [self performInitialScan];
}

- (void)stop
{
    
}

#pragma mark - Scanning -

- (void)performInitialScan
{
    TOFileSystemScanOperation *scanOperation = nil;
    scanOperation = [[TOFileSystemScanOperation alloc] initWithDirectoryItem:self.baseObject.item
                                                          realmConfiguration:self.realmConfiguration];
    [self.operationQueue addOperation:scanOperation];
}

- (void)installDispatchSourceForDirectoryAtURL:(NSURL *)url
{

}

- (void)removeDispatchSourceForDirectoryAtURL:(NSURL *)url
{

}

//- (void)installDispatchSourceForDirectoryAtURL
//{
//    NSURL *filePath = [self.targetDirectoryURL URLByAppendingPathComponent:@"Test"];
//
//    // Get our target directory handle
//    int fd = open(filePath.path.UTF8String, O_EVTONLY);
//    if (fd == -1) { return; }
//
//    // Get the lowest priority queue to work on
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
//    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE|DISPATCH_VNODE_EXTEND|DISPATCH_VNODE_RENAME|DISPATCH_VNODE_FUNLOCK, queue);
//    if (self.dispatchSource == NULL) { return; }
//
//    // Set the event handler
//    dispatch_source_set_event_handler(self.dispatchSource, ^{
//        NSLog(@"Change detected!");
//    });
//
//    // Set a cancel handler
//    dispatch_source_set_cancel_handler(self.dispatchSource, ^{
//        close(fd);
//    });
//
//    // Start observing
//    dispatch_resume(self.dispatchSource);
//}

#pragma mark - Convenience Accessors -

- (RLMRealm *)realm
{
    if (!self.isRunning) { return nil; }

    // Attempt to create possibly the first instance of this realm
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:self.realmConfiguration error:&error];

    // If an error occurs, log it, and return nil.
    if (error) {
        NSLog(@"TOFileSystemObserver: Was unable to start because an error occured in Realm: %@", error.description);
        return nil;
    }

    return realm;
}

- (TOFileSystemBase *)baseObject
{
    // The database won't be configured yet.
    if (!self.isRunning) { return nil; }

    // Return either a newly created object, or one previously stored in Realm
    return [TOFileSystemBase baseObjectInRealm:self.realm forItemAtFileURL:self.targetDirectoryURL];
}

@end
