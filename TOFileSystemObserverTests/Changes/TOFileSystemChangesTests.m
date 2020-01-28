//
//  TOFileSystemChangesTests.m
//  TOFileSystemObserverTests
//
//  Created by Tim Oliver on 2020/01/28.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TOFileSystemObserver.h"
#import "TOFileSystemChanges+Private.h"

@interface TOFileSystemChangesTests : XCTestCase

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, strong) TOFileSystemObserver *observer;
@property (nonatomic, strong) TOFileSystemChanges *changes;

@end

@implementation TOFileSystemChangesTests

- (void)setUp
{
    // Create test data
    self.url = [NSURL fileURLWithPath:@"/Documents"];
    self.uuid = @"0256d425-f081-4bc3-8db5-bcb158568abb";
    
    // Create test objects
    self.observer = [[TOFileSystemObserver alloc] init];
    self.changes = [[TOFileSystemChanges alloc] initWithFileSystemObserver:self.observer];
}

- (void)tearDown
{
    self.url = nil;
    self.uuid = nil;
    self.observer = nil;
    self.changes = nil;
}

- (void)testObserverInChanges
{
    XCTAssertEqual(self.changes.fileSystemObserver, self.observer);
}

- (void)testDiscoveries
{
    // Test we can properly retrieve discovered items that were added
    [self.changes addDiscoveredItemWithUUID:self.uuid fileURL:self.url];
    XCTAssert(self.changes.discoveredItems[self.uuid] == self.url);
}

- (void)testModifications
{
    // Test we can properly retrieve modified items that were added
    [self.changes addModifiedItemWithUUID:self.uuid fileURL:self.url];
    XCTAssert(self.changes.modifiedItems[self.uuid] == self.url);
}

- (void)testDeletions
{
    // Test we can properly retrieve deleted items that were added
    [self.changes addDeletedItemWithUUID:self.uuid fileURL:self.url];
    XCTAssert(self.changes.deletedItems[self.uuid] == self.url);
}

- (void)testMovedItems
{
    // Test we can properly retrieve moved items that were added
    NSURL *newURL = [NSURL fileURLWithPath:@"/Documents/Folder"];
    [self.changes addMovedItemWithUUID:self.uuid oldFileURL:self.url newFileURL:newURL];
    XCTAssert(self.changes.movedItems[self.uuid].firstObject == self.url);
    XCTAssert(self.changes.movedItems[self.uuid].lastObject == newURL);
}

@end
