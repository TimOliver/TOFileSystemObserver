//
//  TOFileSystemItemMapTableTests.m
//  TOFileSystemObserverTests
//
//  Created by Tim Oliver on 2020/01/28.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TOFileSystemItemMapTable.h"

@interface TOFileSystemItemMapTableTests : XCTestCase

@property (nonatomic, strong) TOFileSystemItemMapTable *mapTable;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, strong) NSString *object;

@end

@implementation TOFileSystemItemMapTableTests

- (void)setUp
{
    @autoreleasepool {
        self.mapTable = [[TOFileSystemItemMapTable alloc] init];
        self.uuid = @"0afec03c-ba74-4b87-9941-9c59bb97ccc4";
        self.object = @"XD";
    }

    // Insert the item
    [self.mapTable setItem:self.object forUUID:self.uuid];
}

- (void)tearDown
{
    self.mapTable = nil;
    self.uuid = nil;
    self.object = nil;
}

- (void)testInsertion
{
    XCTAssertEqual(self.mapTable.count, 1);
}

- (void)testRetrieval
{
    XCTAssert([[self.mapTable itemForUUID:self.uuid] isEqualToString:self.object]);
}

- (void)testDeletion
{
    [self.mapTable removeItemForUUID:self.uuid];
    XCTAssertEqual(self.mapTable.count, 0);
}

- (void)testAllItemsSnapshotIsIndependentOfTable
{
    NSString *second = @"second";
    [self.mapTable setItem:second forUUID:@"second-uuid"];

    NSArray *snapshot = [self.mapTable allItems];
    XCTAssertEqual(snapshot.count, 2);
    XCTAssertTrue([snapshot containsObject:self.object]);
    XCTAssertTrue([snapshot containsObject:second]);

    // Mutating the table after taking a snapshot must not change the snapshot.
    [self.mapTable removeItemForUUID:self.uuid];
    [self.mapTable removeItemForUUID:@"second-uuid"];
    XCTAssertEqual(self.mapTable.count, 0);
    XCTAssertEqual(snapshot.count, 2);
}

- (void)testAllItemsOnEmptyTableReturnsEmptyArray
{
    [self.mapTable removeItemForUUID:self.uuid];
    NSArray *snapshot = [self.mapTable allItems];
    XCTAssertNotNil(snapshot);
    XCTAssertEqual(snapshot.count, 0);
}

@end
