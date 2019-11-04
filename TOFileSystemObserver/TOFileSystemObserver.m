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
#import "TOFileSystemPresenter.h"

@interface TOFileSystemObserver()

/** The absolute path to our observed directory's super directory so we can build paths. */
@property (nonatomic, strong) NSURL *parentDirectoryURL;

/** Read-write access for the running state */
@property (nonatomic, assign, readwrite) BOOL isRunning;

/** Temporarily skip an event if we're explicitly touching the file system. */
@property (nonatomic, assign) BOOL skipEvents;

/** A file presenter object that will observe our file system */
@property (nonatomic, strong) TOFileSystemPresenter *fileSystemPresenter;

/** The operation queue we will perform our scanning on. */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/** The configuration for the Realm database we'll be using. */
@property (nonatomic, strong) RLMRealmConfiguration *realmConfiguration;

/** Gets a new copy of the Realm database backing this observer. */
@property (nonatomic, readonly) RLMRealm *realm;

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
    _databaseFileName = [TOFileSystemPath defaultDatabaseFileName];
    _databaseDirectoryURL = [TOFileSystemPath cachesDirectoryURL];
    _parentDirectoryURL = [_directoryURL URLByDeletingLastPathComponent];
    
    // Set-up the operation queue
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    _operationQueue.qualityOfService = NSQualityOfServiceBackground;

    // Set up the file system presenter
    _fileSystemPresenter = [[TOFileSystemPresenter alloc] init];
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

    // Then try creating our base item for our taget folder for the first time
    TOFileSystemItem *baseItem = self.directoryItem;
    if (baseItem == nil) { return NO; }
    
    return YES;
}

- (void)configureFilePresenter
{
    __weak typeof(self) weakSelf = self;
    self.fileSystemPresenter.itemsDidChangeHandler = ^(NSArray *itemURLs) {
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

    // Set up and configure our backing data store
    if (![self configureDatabase]) {
        [self stop];
        return;
    }

    // Configure the source observer to send change events to us
    [self configureFilePresenter];

    // Set up observer for the top level directory
    [self beginObservingBaseDirectory];
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
                                                                         uuid:self.baseObject.item.uuid
                                                           realmConfiguration:self.realmConfiguration];

    // Begin asynchronous execution
    [self.operationQueue addOperation:scanOperation];
}

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

- (TOFileSystemItem *)directoryItem
{
    // The database isn't created until the observer has been started
    if (!self.isRunning) { return nil; }

    // Grab a local instance of Realm to save recreating it for each
    RLMRealm *realm = self.realm;
    
    // See if there already exists an item for this directory in Realm
    TOFileSystemItem *item = [TOFileSystemItem itemInRealm:self.realm forItemAtURL:self.directoryURL];
    
    // If not, create a new one and persist it
    if (item == nil) {
        item = [[TOFileSystemItem alloc] initWithItemAtFileURL:self.directoryURL];
        id block = ^{ [realm addObject:item]; };
        [realm transactionWithBlock:block];
    }
    
    return item;
}

@end
