//
//  TOFileSystemObserverIntegrationTests.m
//
//  Copyright 2019-2026 Timothy Oliver. All rights reserved.
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

#import <XCTest/XCTest.h>
#import "TOFileSystemObserver.h"
#import "TOFileSystemItemList+Private.h"
#import "TOFileSystemPath.h"
#import "NSURL+TOFileSystemUUID.h"

// Re-declare the scan-operation delegate methods on TOFileSystemObserver so
// tests can drive them directly. Saves us from the inherent flakiness of
// trying to coax NSFilePresenter into firing the right callback for a deep
// subdirectory event. The protocol is implementation-private — runtime
// dispatch finds the methods on the class regardless of header visibility.
@class TOFileSystemScanOperation;

@interface TOFileSystemObserver (TestingHook)
- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation
         itemWithUUID:(NSString *)uuid
        didMoveFromURL:(NSURL *)previousURL
                toURL:(NSURL *)url;
@end

// Scans complete in well under a second under normal conditions. A larger
// budget than that gives slow CI hardware some headroom while still failing
// fast if a regression brings back cross-instance serialisation.
static const NSTimeInterval kTestScanTimeout = 10.0;

@interface TOFileSystemObserverIntegrationTests : XCTestCase

@property (nonatomic, strong) NSURL *tempDirectory;
@property (nonatomic, strong) TOFileSystemObserver *observer;
@property (nonatomic, strong) NSMutableArray<TOFileSystemNotificationToken *> *tokens;

@end

@implementation TOFileSystemObserverIntegrationTests

- (void)setUp
{
    [super setUp];

    NSString *uniqueName = [@"to-observer-tests-" stringByAppendingString:[NSUUID UUID].UUIDString];
    self.tempDirectory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:uniqueName]];
    [NSFileManager.defaultManager createDirectoryAtURL:self.tempDirectory
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];

    self.observer = [[TOFileSystemObserver alloc] initWithDirectoryURL:self.tempDirectory];
    self.tokens = [NSMutableArray array];
}

- (void)tearDown
{
    if (self.observer.isRunning) {
        [self.observer stop];
    }
    for (TOFileSystemNotificationToken *token in self.tokens) {
        [token invalidate];
    }
    [self.tokens removeAllObjects];
    self.observer = nil;

    [NSFileManager.defaultManager removeItemAtURL:self.tempDirectory error:nil];
    self.tempDirectory = nil;

    [super tearDown];
}

- (void)testInitWithDirectoryURLPointsAtThatDirectory
{
    XCTAssertEqualObjects(self.observer.directoryURL.path, self.tempDirectory.path);
    XCTAssertFalse(self.observer.isRunning);
}

- (void)testDirectoryItemRepresentsObservedDirectory
{
    TOFileSystemItem *item = self.observer.directoryItem;
    XCTAssertNotNil(item);
    XCTAssertEqualObjects(item.fileURL.URLByStandardizingPath.path,
                          self.tempDirectory.URLByStandardizingPath.path);
    XCTAssertNotNil(item.uuid);
}

- (void)testStartAndStopUpdateIsRunning
{
    XCTAssertFalse(self.observer.isRunning);
    [self.observer start];
    XCTAssertTrue(self.observer.isRunning);
    [self.observer stop];
    XCTAssertFalse(self.observer.isRunning);
}

- (void)testStartFiresFullScanNotifications
{
    XCTestExpectation *willBegin = [self expectationWithDescription:@"WillBeginFullScan fires"];
    XCTestExpectation *didComplete = [self expectationWithDescription:@"DidCompleteFullScan fires"];

    TOFileSystemNotificationToken *token = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type == TOFileSystemObserverNotificationTypeWillBeginFullScan) {
            [willBegin fulfill];
        } else if (type == TOFileSystemObserverNotificationTypeDidCompleteFullScan) {
            [didComplete fulfill];
        }
    }];
    [self.tokens addObject:token];

    [self.observer start];
    [self waitForExpectations:@[willBegin, didComplete] timeout:kTestScanTimeout];
}

- (void)testTokenInvalidatedDuringDispatchStillReceivesCurrentNotification
{
    // Regression: notification dispatch iterates a snapshot of the token table,
    // so a block invalidating another token mid-loop must not skip or crash on it.
    XCTestExpectation *firstFired = [self expectationWithDescription:@"first token fired"];
    XCTestExpectation *secondFired = [self expectationWithDescription:@"second token fired"];

    __block TOFileSystemNotificationToken *secondToken = nil;

    TOFileSystemNotificationToken *firstToken = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type != TOFileSystemObserverNotificationTypeWillBeginFullScan) { return; }
        [secondToken invalidate];
        [firstFired fulfill];
    }];

    secondToken = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type != TOFileSystemObserverNotificationTypeWillBeginFullScan) { return; }
        [secondFired fulfill];
    }];

    [self.tokens addObject:firstToken];
    [self.tokens addObject:secondToken];

    [self.observer start];
    [self waitForExpectations:@[firstFired, secondFired] timeout:kTestScanTimeout];
}

- (void)testItemListSynchronizeWithDiskRemovesNonContiguousDeletedItems
{
    // Regression: deletions used to be applied by ascending stale index, so
    // non-contiguous deletions mis-targeted the second-and-later removals
    // because earlier removals shifted the array.
    NSMutableArray<NSURL *> *fileURLs = [NSMutableArray array];
    NSMutableArray<NSString *> *uuids = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        NSURL *fileURL = [self.tempDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"file-%ld.dat", (long)i]];
        [@"x" writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSString *uuid = [fileURL to_generateFileSystemUUID];
        XCTAssertNotNil(uuid);
        [fileURLs addObject:fileURL];
        [uuids addObject:uuid];
    }

    TOFileSystemItemList *list = [[TOFileSystemItemList alloc] initWithDirectoryURL:self.tempDirectory
                                                                fileSystemObserver:self.observer];
    for (NSInteger i = 0; i < 5; i++) {
        [list addItemWithUUID:uuids[i] itemURL:fileURLs[i]];
    }
    XCTAssertEqual(list.count, 5);

    // Delete the files at indices 1 and 3 — non-contiguous, so reverse-iteration
    // order is what keeps the indices valid for both removals.
    [NSFileManager.defaultManager removeItemAtURL:fileURLs[1] error:nil];
    [NSFileManager.defaultManager removeItemAtURL:fileURLs[3] error:nil];

    [list synchronizeWithDisk];

    XCTAssertEqual(list.count, 3);
    NSMutableSet<NSString *> *expected = [NSMutableSet setWithObjects:uuids[0], uuids[2], uuids[4], nil];
    NSMutableSet<NSString *> *actual = [NSMutableSet set];
    for (NSUInteger i = 0; i < list.count; i++) {
        [actual addObject:list[i].uuid];
    }
    XCTAssertEqualObjects(expected, actual);
}

- (void)testBroadcastsNotificationsPostsToNotificationCenter
{
    self.observer.broadcastsNotifications = YES;

    XCTestExpectation *willBegin = [self expectationForNotification:TOFileSystemObserverWillBeginFullScanNotification
                                                             object:nil
                                                            handler:nil];
    XCTestExpectation *didComplete = [self expectationForNotification:TOFileSystemObserverDidCompleteFullScanNotification
                                                               object:nil
                                                              handler:nil];

    [self.observer start];
    [self waitForExpectations:@[willBegin, didComplete] timeout:kTestScanTimeout];
}

- (void)testItemListIsDescendingTriggersResort
{
    // Exercises setIsDescending, rebuildItemListForListingOrder, and the
    // sort-comparator block that drives them.
    NSArray<NSString *> *names = @[@"a.txt", @"b.txt", @"c.txt"];
    NSMutableDictionary<NSString *, NSString *> *uuidsByName = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSURL *> *urlsByName = [NSMutableDictionary dictionary];
    for (NSString *name in names) {
        NSURL *url = [self.tempDirectory URLByAppendingPathComponent:name];
        [@"x" writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
        urlsByName[name] = url;
        uuidsByName[name] = [url to_generateFileSystemUUID];
        XCTAssertNotNil(uuidsByName[name]);
    }

    TOFileSystemItemList *list = [[TOFileSystemItemList alloc] initWithDirectoryURL:self.tempDirectory
                                                                fileSystemObserver:self.observer];
    for (NSString *name in names) {
        [list addItemWithUUID:uuidsByName[name] itemURL:urlsByName[name]];
    }

    // Default order is alphanumeric ascending.
    XCTAssertEqualObjects(list[0].name, @"a.txt");
    XCTAssertEqualObjects(list[2].name, @"c.txt");

    list.isDescending = YES;
    XCTAssertEqualObjects(list[0].name, @"c.txt");
    XCTAssertEqualObjects(list[2].name, @"a.txt");

    list.isDescending = NO;
    XCTAssertEqualObjects(list[0].name, @"a.txt");
}

- (void)testFileCreationAfterStartFiresChangeNotification
{
    // Wait for the initial scan to settle, then create a file and confirm a
    // non-full-scan DidChange notification fires. Exercises the entire
    // NSFilePresenter -> beginTimer -> item-scan path.
    XCTestExpectation *initialScanComplete = [self expectationWithDescription:@"initial scan complete"];
    XCTestExpectation *changeReceived = [self expectationWithDescription:@"file creation observed"];
    changeReceived.assertForOverFulfill = NO;

    TOFileSystemNotificationToken *token = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type == TOFileSystemObserverNotificationTypeDidCompleteFullScan) {
            [initialScanComplete fulfill];
        } else if (type == TOFileSystemObserverNotificationTypeDidChange && !changes.isFullScan) {
            [changeReceived fulfill];
        }
    }];
    [self.tokens addObject:token];

    [self.observer start];
    [self waitForExpectations:@[initialScanComplete] timeout:kTestScanTimeout];

    NSURL *newFile = [self.tempDirectory URLByAppendingPathComponent:@"new-file.dat"];
    [@"new" writeToURL:newFile atomically:YES encoding:NSUTF8StringEncoding error:nil];

    [self waitForExpectations:@[changeReceived] timeout:kTestScanTimeout];
}

- (void)testApplicationSandboxURLReturnsAReadableHomeDirectory
{
    NSURL *sandbox = [TOFileSystemPath applicationSandboxURL];
    XCTAssertNotNil(sandbox);
    XCTAssertTrue(sandbox.isFileURL);
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:sandbox.path]);
}

- (void)testItemListDescriptionIncludesURLAndUUID
{
    NSURL *fileURL = [self.tempDirectory URLByAppendingPathComponent:@"described.dat"];
    [@"x" writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *uuid = [fileURL to_generateFileSystemUUID];

    TOFileSystemItemList *list = [[TOFileSystemItemList alloc] initWithDirectoryURL:self.tempDirectory
                                                                fileSystemObserver:self.observer];
    [list addItemWithUUID:uuid itemURL:fileURL];

    NSString *description = list.description;
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:self.tempDirectory.lastPathComponent]);
}

- (void)testItemListRemoveItemWithUUIDDropsItemFromList
{
    // Add two files so the list has something left after the remove. (`count`
    // re-scans from disk if `sortedItems` is empty, which would re-add the
    // single file we just removed.)
    NSURL *firstURL = [self.tempDirectory URLByAppendingPathComponent:@"keep.dat"];
    NSURL *secondURL = [self.tempDirectory URLByAppendingPathComponent:@"to-remove.dat"];
    [@"x" writeToURL:firstURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [@"x" writeToURL:secondURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *firstUUID = [firstURL to_generateFileSystemUUID];
    NSString *secondUUID = [secondURL to_generateFileSystemUUID];

    TOFileSystemItemList *list = [[TOFileSystemItemList alloc] initWithDirectoryURL:self.tempDirectory
                                                                fileSystemObserver:self.observer];
    [list addItemWithUUID:firstUUID itemURL:firstURL];
    [list addItemWithUUID:secondUUID itemURL:secondURL];
    XCTAssertEqual(list.count, 2);

    [list removeItemWithUUID:secondUUID fileURL:secondURL];
    XCTAssertEqual(list.count, 1);
    XCTAssertEqualObjects(list[0].uuid, firstUUID);
}

- (void)testFileDeletionAfterStartFiresChangeNotification
{
    // Pre-create a file so the initial scan picks it up; deletion then triggers
    // the item-scan + cleanUpFilesPendingDeletion + didDeleteItemAtURL path.
    NSURL *target = [self.tempDirectory URLByAppendingPathComponent:@"to-delete.dat"];
    [@"x" writeToURL:target atomically:YES encoding:NSUTF8StringEncoding error:nil];

    XCTestExpectation *initialScanComplete = [self expectationWithDescription:@"initial scan complete"];
    XCTestExpectation *deletionObserved = [self expectationWithDescription:@"deletion observed"];
    deletionObserved.assertForOverFulfill = NO;

    TOFileSystemNotificationToken *token = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type == TOFileSystemObserverNotificationTypeDidCompleteFullScan) {
            [initialScanComplete fulfill];
        } else if (type == TOFileSystemObserverNotificationTypeDidChange &&
                   !changes.isFullScan &&
                   changes.deletedItems.count > 0) {
            [deletionObserved fulfill];
        }
    }];
    [self.tokens addObject:token];

    [self.observer start];
    [self waitForExpectations:@[initialScanComplete] timeout:kTestScanTimeout];

    [NSFileManager.defaultManager removeItemAtURL:target error:nil];

    [self waitForExpectations:@[deletionObserved] timeout:kTestScanTimeout];
}

- (void)testSharedObserverReturnsSameInstanceAndBroadcastsByDefault
{
    TOFileSystemObserver *first = [TOFileSystemObserver sharedObserver];
    TOFileSystemObserver *second = [TOFileSystemObserver sharedObserver];
    XCTAssertNotNil(first);
    XCTAssertEqual(first, second);
    XCTAssertTrue(first.broadcastsNotifications);
}

- (void)testSetSharedObserverReplacesAndStopsExisting
{
    // Capture the lazy-init singleton (which targets Documents — never start
    // it here, that triggers a scan on the test host's real Documents dir).
    TOFileSystemObserver *previousShared = [TOFileSystemObserver sharedObserver];

    // Use the test's own temp-dir observer as a stand-in "currently active
    // singleton" so we can verify that setSharedObserver: stops a running
    // predecessor without scanning a directory we don't control.
    [TOFileSystemObserver setSharedObserver:self.observer];
    [self.observer start];
    XCTAssertTrue(self.observer.isRunning);

    TOFileSystemObserver *replacement = [[TOFileSystemObserver alloc] initWithDirectoryURL:self.tempDirectory];
    [TOFileSystemObserver setSharedObserver:replacement];

    XCTAssertEqual([TOFileSystemObserver sharedObserver], replacement);
    XCTAssertFalse(self.observer.isRunning);

    // Restore so subsequent tests see the original lazy-init singleton.
    [TOFileSystemObserver setSharedObserver:previousShared];
}

- (void)testFileModificationFiresItemDidChangeAndCopyTimer
{
    // Pre-create a file so the initial scan registers it as a known item.
    // Subsequent modifications then take the itemDidChangeAtURL path (rather
    // than didDiscoverItemAtURL) and trigger the copy timer because the
    // modification date is "now" — which is what we want to exercise.
    NSURL *target = [self.tempDirectory URLByAppendingPathComponent:@"to-modify.dat"];
    [@"original" writeToURL:target atomically:YES encoding:NSUTF8StringEncoding error:nil];

    XCTestExpectation *initialScanComplete = [self expectationWithDescription:@"initial scan complete"];
    XCTestExpectation *modificationObserved = [self expectationWithDescription:@"modification observed"];
    modificationObserved.assertForOverFulfill = NO;

    TOFileSystemNotificationToken *token = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type == TOFileSystemObserverNotificationTypeDidCompleteFullScan) {
            [initialScanComplete fulfill];
        } else if (type == TOFileSystemObserverNotificationTypeDidChange &&
                   !changes.isFullScan &&
                   changes.modifiedItems.count > 0) {
            [modificationObserved fulfill];
        }
    }];
    [self.tokens addObject:token];

    [self.observer start];
    [self waitForExpectations:@[initialScanComplete] timeout:kTestScanTimeout];

    [@"modified" writeToURL:target atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self waitForExpectations:@[modificationObserved] timeout:kTestScanTimeout];

    // Hold the run loop open long enough for the copy timer to fire so its
    // completion path (copyTimerCompleted -> updateObservingObjects) runs.
    XCTestExpectation *copyTimerWindow = [self expectationWithDescription:@"copy-timer window"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ [copyTimerWindow fulfill]; });
    [self waitForExpectations:@[copyTimerWindow] timeout:10.0];
}

- (void)testCrossDirectoryMoveHandlerProducesMovedChange
{
    // Synthetic test: drive the scan-op delegate method directly with realistic
    // arguments and verify the broadcast carries a moved-item change. The
    // NSFilePresenter-driven version of this is order-flaky in the full suite
    // because subdirectory event timing varies; calling the handler ourselves
    // exercises the same code path deterministically.
    NSURL *folderA = [self.tempDirectory URLByAppendingPathComponent:@"A"];
    NSURL *folderB = [self.tempDirectory URLByAppendingPathComponent:@"B"];
    [NSFileManager.defaultManager createDirectoryAtURL:folderA withIntermediateDirectories:YES attributes:nil error:nil];
    [NSFileManager.defaultManager createDirectoryAtURL:folderB withIntermediateDirectories:YES attributes:nil error:nil];
    XCTAssertNotNil([folderA to_generateFileSystemUUID]);
    XCTAssertNotNil([folderB to_generateFileSystemUUID]);

    NSURL *source = [folderA URLByAppendingPathComponent:@"foo.dat"];
    NSURL *destination = [folderB URLByAppendingPathComponent:@"foo.dat"];
    [@"x" writeToURL:destination atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *uuid = [destination to_generateFileSystemUUID];
    XCTAssertNotNil(uuid);

    XCTestExpectation *moveObserved = [self expectationWithDescription:@"move observed"];
    moveObserved.assertForOverFulfill = NO;

    TOFileSystemNotificationToken *token = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type == TOFileSystemObserverNotificationTypeDidChange &&
            changes.movedItems.count > 0) {
            [moveObserved fulfill];
        }
    }];
    [self.tokens addObject:token];

    [self.observer scanOperation:nil itemWithUUID:uuid didMoveFromURL:source toURL:destination];

    [self waitForExpectations:@[moveObserved] timeout:kTestScanTimeout];
}

- (void)testStopThenStartAgainPerformsAnotherFullScan
{
    XCTestExpectation *firstScan = [self expectationWithDescription:@"first scan completes"];
    XCTestExpectation *secondScan = [self expectationWithDescription:@"second scan completes"];
    secondScan.assertForOverFulfill = NO;

    __block NSInteger completionCount = 0;
    TOFileSystemNotificationToken *token = [self.observer addNotificationBlock:
        ^(TOFileSystemObserver *observer,
          TOFileSystemObserverNotificationType type,
          TOFileSystemChanges *changes)
    {
        if (type != TOFileSystemObserverNotificationTypeDidCompleteFullScan) { return; }
        completionCount++;
        if (completionCount == 1) { [firstScan fulfill]; }
        if (completionCount == 2) { [secondScan fulfill]; }
    }];
    [self.tokens addObject:token];

    [self.observer start];
    [self waitForExpectations:@[firstScan] timeout:kTestScanTimeout];

    [self.observer stop];
    XCTAssertFalse(self.observer.isRunning);

    [self.observer start];
    [self waitForExpectations:@[secondScan] timeout:kTestScanTimeout];
}

@end
