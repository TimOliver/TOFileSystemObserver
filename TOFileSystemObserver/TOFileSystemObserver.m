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
#import "TOFileSystemScanOperation.h"
#import "TOFileSystemPresenter.h"
#import "TOFileSystemItemList+Private.h"

#import "NSURL+TOFileSystemUUID.h"

@interface TOFileSystemObserver()

/** The absolute path to our observed directory's super directory so we can build paths. */
@property (nonatomic, strong) NSURL *parentDirectoryURL;

/** The UUID of the observed directory on disk, so we can easily access it in scans. */
@property (nonatomic, copy) NSString *baseDirectoryUUID;

/** Read-write access for the running state */
@property (nonatomic, assign, readwrite) BOOL isRunning;

/** Temporarily skip an event if we're explicitly touching the file system. */
@property (nonatomic, assign) BOOL skipEvents;

/** A file presenter object that will observe our file system */
@property (nonatomic, strong) TOFileSystemPresenter *fileSystemPresenter;

/** The operation queue we will perform our scanning on. */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/** A hash table that weakly holds item list objects */
@property (nonatomic, strong) NSMapTable *itemListTable;

@end

@implementation TOFileSystemObserver

#pragma mark - Object Lifecycle -

- (instancetype)init
{
    if (self = [super init]) {
        _directoryURL = [TOFileSystemPath documentsDirectoryURL];
        [self setUp];
    }

    return self;
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
{
    if (self = [super init]) {
        _directoryURL = directoryURL;
        [self setUp];
    }

    return self;
}

- (void)setUp
{
    // Set-up default property values
    _isRunning = NO;
    _excludedItems = @[@"Inbox"];
    
    // Set-up the operation queue
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    _operationQueue.qualityOfService = NSQualityOfServiceBackground;

    // Set up the file system presenter
    _fileSystemPresenter = [[TOFileSystemPresenter alloc] init];
    
    // Set up the hash table
    _itemListTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsCopyIn
                                               valueOptions:NSPointerFunctionsWeakMemory
                                                   capacity:0];
}

#pragma mark - Observer Setup -

- (void)configureFilePresenter
{
    __weak typeof(self) weakSelf = self;
    self.fileSystemPresenter.itemsDidChangeHandler = ^(NSArray *itemURLs) {
        NSLog(@"%@", itemURLs);
        //[weakSelf performScanWithItems:itemURLs];
    };
}

- (void)beginObservingBaseDirectory
{
    // Attach the root directory to the observer
    NSURL *url = self.directoryURL;
    self.fileSystemPresenter.directoryURL = url;

    // Set the detect handler
    [self configureFilePresenter];

    // Start the handler
    [self.fileSystemPresenter start];
}

#pragma mark - Observer Lifecycle -

- (void)start
{
    if (self.isRunning) { return; }

    // Set the running state
    self.isRunning = YES;

    // Lock in the properties of the base directory
    _parentDirectoryURL = [_directoryURL URLByDeletingLastPathComponent];
    _baseDirectoryUUID = self.directoryItem.uuid;

    // Configure the source observer to send change events to us
    [self configureFilePresenter];

    // Start the observer to watch for any system level changes
    [self beginObservingBaseDirectory];

    // Kick off an initial scan of the entire file hierarchy
    [self performFullDirectoryScan];
}

- (void)stop
{
    if (!self.isRunning) { return; }

    // Set the running state to off
    self.isRunning = NO;

    // Remove all of the observers
    [self.fileSystemPresenter stop];
}

#pragma mark - Scanning -

- (void)performFullDirectoryScan
{
    // Cancel any in progress operations since we'll be starting again
    [self.operationQueue cancelAllOperations];

    // Create a new scan operation
    TOFileSystemScanOperation *scanOperation = nil;
    scanOperation = [[TOFileSystemScanOperation alloc] initWithDirectoryAtURL:self.directoryURL
                                                                filePresenter:self.fileSystemPresenter];

    // Begin asynchronous execution
    [self.operationQueue addOperation:scanOperation];
}

#pragma mark - Creating Observing Objects -

- (TOFileSystemItemList *)itemListForDirectoryAtURL:(NSURL *)directoryURL
{
    // Default to the base directory if nil is supplied
    if (directoryURL == nil) {
        directoryURL = self.directoryURL;
    }
    
    // Fetch the UUID for this item and see if we've cached it already
    NSString *uuid = [directoryURL to_fileSystemUUID];
    TOFileSystemItemList *itemList = [self.itemListTable objectForKey:uuid];
    if (itemList) { return itemList; }
    
    // Create a new one, and save it to the map table
    itemList = [[TOFileSystemItemList alloc] initWithDirectoryURL:directoryURL
                                                                     fileSystemObserver:self];
    [self.itemListTable setObject:itemList forKey:itemList];
    return itemList;
}

@end
