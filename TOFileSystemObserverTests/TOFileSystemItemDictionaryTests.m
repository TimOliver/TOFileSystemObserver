//
//  TOFileSystemObserverTests.m
//  TOFileSystemObserverTests
//
//  Created by Tim Oliver on 2019/12/27.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TOFileSystemItemDictionary.h"

@interface TOFileSystemItemDictionaryTests : XCTestCase

@end

@implementation TOFileSystemItemDictionaryTests

- (void)testCreation
{
    TOFileSystemItemDictionary *dict = [[TOFileSystemItemDictionary alloc] init];
    XCTAssertNotNil(dict);
}

- (void)testInsertionAndDeletion
{
    TOFileSystemItemDictionary *dict = [[TOFileSystemItemDictionary alloc] init];
    
    // Test first insertion
    NSURL *url = [NSURL URLWithString:@"https://www.google.com"];
    dict[@"google"] = url;
    XCTAssertEqual(dict[@"google"], url);
    
    // Test second insertion
    url = [NSURL URLWithString:@"https://www.bing.com"];
    dict[@"google"] = url;
    XCTAssertEqual(dict[@"google"], url);
    
    // Test deletion
    dict[@"google"] = nil;
    XCTAssertNil(dict[@"google"]);
}

- (void)testConcurrentReads
{
    TOFileSystemItemDictionary *dict = [[TOFileSystemItemDictionary alloc] init];
    
    NSURL *url = [NSURL URLWithString:@"https://www.google.com"];
    dict[@"google"] = url;
    
    // Check read is working on the main thread
    XCTAssertEqual(dict[@"google"], url);
    
    // Create expectation to test concurrent execution
    XCTestExpectation *expectation = [[XCTestExpectation alloc]
                                      initWithDescription:@"Dictionary Reads Succeeded"];
    
    // Create dispatch group so we can call a trigger when both queues finish executing
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    // Kickstart a read on the first thread
    dispatch_queue_t firstQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, firstQueue, ^ {
        XCTAssertEqual(dict[@"google"], url);
    });

    // Kickstart a read on the second thread
    dispatch_queue_t secondQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, secondQueue, ^ {
        XCTAssertEqual(dict[@"google"], url);
    });
    
    // Upon completion of both reads, ensure the dictionary contains both values
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_group_notify(dispatchGroup, mainQueue, ^ {
        [expectation fulfill];
    });
    
    // Wait for the expectation
    [self waitForExpectations:@[expectation] timeout:1.0f];
}

- (void)testConcurrentWrite
{
    TOFileSystemItemDictionary *dict = [[TOFileSystemItemDictionary alloc] init];
    
    // Create some test URLs to inject
    NSURL *firstUrl = [NSURL URLWithString:@"https://www.google.com"];
    NSURL *secondUrl = [NSURL URLWithString:@"https://www.bing.com"];
    
    // Create expectation to test concurrent execution
    XCTestExpectation *expectation = [[XCTestExpectation alloc]
                                      initWithDescription:@"Dictionary Writes Succeeded"];
    
    // Create dispatch group so we can call a trigger when both queues finish executing
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    // Kickstart a write on the first thread
    dispatch_queue_t firstQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, firstQueue, ^ {
        [dict setItemURL:firstUrl forUUID:@"google"];
    });

    // Kickstart a write on the second thread
    dispatch_queue_t secondQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, secondQueue, ^ {
        [dict setItemURL:secondUrl forUUID:@"bing"];
    });

    // Upon completion of both writes, ensure the dictionary contains both values
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_group_notify(dispatchGroup, mainQueue, ^ {
        XCTAssertEqual([dict itemURLForUUID:@"google"], firstUrl);
        XCTAssertEqual([dict itemURLForUUID:@"bing"], secondUrl);
        XCTAssertNil([dict itemURLForUUID:@"yahoo"]);
        [expectation fulfill];
    });
    
    // Wait for the expectation
    [self waitForExpectations:@[expectation] timeout:1.0f];
}

@end
