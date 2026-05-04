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
#import "NSURL+TOFileSystemUUID.h"

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
