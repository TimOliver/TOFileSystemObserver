//
//  TOFileSystemItemURLDictionaryTests.m
//  TOFileSystemObserverTests
//
//  Created by Tim Oliver on 2020/01/28.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TOFileSystemPath.h"
#import "TOFileSystemItemURLDictionary.h"


@interface TOFileSystemItemURLDictionaryTests : XCTestCase

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) TOFileSystemItemURLDictionary *dictionary;

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) NSString *uuid;

@end

@implementation TOFileSystemItemURLDictionaryTests

- (void)setUp
{
    // Create a test object
    self.baseURL = [TOFileSystemPath documentsDirectoryURL];
    self.dictionary = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.baseURL];
    
    // Create some basic test data
    self.url = [self.baseURL URLByAppendingPathComponent:@"Folder"];
    self.uuid = @"f2a5bc6d-0eab-4970-8650-8629fdc3a866";
    
    // Insert the test data
    [self.dictionary setItemURL:self.url forUUID:self.uuid];
}

- (void)tearDown
{
    self.baseURL = nil;
    self.dictionary = nil;
    self.url = nil;
    self.uuid = nil;
}

- (void)testInserting
{
    // Verify the insertion was stored correctly
    XCTAssertEqual(self.dictionary.count, 1);
}

- (void)testRetrieval
{
    // Retrieve the URL and verify it matches what was inserted
    XCTAssert([[self.dictionary itemURLForUUID:self.uuid] isEqual:self.url]);
    
    // Perform an inverse lookup
    XCTAssert([[self.dictionary uuidForItemWithURL:self.url] isEqualToString:self.uuid]);
}

- (void)testSubscripting
{
    self.dictionary[self.uuid] = self.url;
    
    // Verify the insertion was stored correctly
    XCTAssertEqual(self.dictionary.count, 1);
    
    // Retrieve the URL and verify it matches what was inserted
    XCTAssert([self.dictionary[self.uuid] isEqual:self.url]);
}

- (void)testNullability
{
    // Test nilling the value removes it
    self.dictionary[self.uuid] = nil;
    XCTAssertEqual(self.dictionary.count, 0);
}

- (void)testRemovingSpecificItem
{
    // Test deleting a specific item works
    [self.dictionary removeItemURLForUUID:self.uuid];
    XCTAssertEqual(self.dictionary.count, 0);
}

- (void)testRemovingAllItems
{
    // Test deleting all items
    [self.dictionary removeAllItems];
    XCTAssertEqual(self.dictionary.count, 0);
}

- (void)testConcurrency
{
    dispatch_group_t group = dispatch_group_create();
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc]
                                      initWithDescription:@"Both queues executed as expected"];
    
    // Blank the dictionary before we start
    [self.dictionary removeAllItems];
    
    // First queue execution
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.dictionary[self.uuid] = self.url;
    });
    
    // Second queue execution
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *url = [self.baseURL URLByAppendingPathComponent:@"Folder2"];
        NSString *uuid = @"3ccd0073-e57c-42c7-b3be-6410a051c900";
        self.dictionary[uuid] = url;
    });
    
    // Wait for completion
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        XCTAssertEqual(self.dictionary.count, 2);
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:0.5f];
}

@end
