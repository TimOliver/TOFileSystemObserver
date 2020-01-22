//
//  TOFileSystemItemListChangesTests.m
//
//  Copyright 2019-2020 Timothy Oliver. All rights reserved.
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

#import "TOFileSystemItemListChanges.h"
#import "TOFileSystemItemListChanges+Private.h"

@interface TOFileSystemItemListChangesTests : XCTestCase

@end

@implementation TOFileSystemItemListChangesTests

- (void)testInsertionIndices
{
    // Add an insertion index
    TOFileSystemItemListChanges *changes = [[TOFileSystemItemListChanges alloc] init];
    [changes addInsertionIndex:1];
    
    // Test that changes are recognized
    XCTAssertTrue(changes.hasItemChanges);
    
    // Check the insertion state
    XCTAssert([changes.insertions isEqualToArray:@[@1]]);
    
    // Check the index path mapping
    NSIndexPath *indexPath = [changes indexPathsForInsertionsInSection:1].firstObject;
    XCTAssertNotNil(indexPath);
    XCTAssertEqual(indexPath.row, 1);
    XCTAssertEqual(indexPath.section, 1);
}

- (void)testDeletionsIndices
{
    // Add a deletion index
    TOFileSystemItemListChanges *changes = [[TOFileSystemItemListChanges alloc] init];
    [changes addDeletionIndex:1];
    
    // Test that changes are recognized
    XCTAssertTrue(changes.hasItemChanges);
    
    // Check the deletion state
    XCTAssert([changes.deletions isEqualToArray:@[@1]]);
    
    // Check the index path mapping
    NSIndexPath *indexPath = [changes indexPathsForDeletionsInSection:1].firstObject;
    XCTAssertNotNil(indexPath);
    XCTAssertEqual(indexPath.row, 1);
    XCTAssertEqual(indexPath.section, 1);

}

- (void)testModificationIndices
{
    // Add a deletion index
    TOFileSystemItemListChanges *changes = [[TOFileSystemItemListChanges alloc] init];
    [changes addModificationIndex:1];
    
    // Test that changes are recognized
    XCTAssertTrue(changes.hasItemChanges);
    
    // Check the deletion state
    XCTAssert([changes.modificatons isEqualToArray:@[@1]]);
    
    // Check the index path mapping
    NSIndexPath *indexPath = [changes indexPathsForModificationsInSection:1].firstObject;
    XCTAssertNotNil(indexPath);
    XCTAssertEqual(indexPath.row, 1);
    XCTAssertEqual(indexPath.section, 1);
}

- (void)testIndexMovements
{
    // Add a movement index
    TOFileSystemItemListChanges *changes = [[TOFileSystemItemListChanges alloc] init];
    [changes addMovementWithSourceIndex:1 destinationIndex:2];
    
    // Check that the state has been validated
    XCTAssertTrue(changes.hasItemMovements);
    
    // Check the movement state
    XCTAssert([changes.movements[@1] isEqualToNumber:@2]);
    
    // Check the index path mapping
    NSArray *sourceIndices = [changes indexPathsForMovementSourcesInSection:1];
    NSArray *destIndices = [changes indexPathsForMovementDestinationsWithSourceIndexPaths:sourceIndices];
    XCTAssert(sourceIndices.count == destIndices.count);

    // Check the index paths
    NSIndexPath *sourceIndexPath = sourceIndices.firstObject;
    XCTAssertEqual(sourceIndexPath.section, 1);
    XCTAssertEqual(sourceIndexPath.row, 1);
    
    NSIndexPath *destIndexPath = destIndices.firstObject;
    XCTAssertEqual(destIndexPath.section, 1);
    XCTAssertEqual(destIndexPath.row, 2);
}

@end
