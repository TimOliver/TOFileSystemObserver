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
