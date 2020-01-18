//
//  TOFileSystemItemDictionaryTests.m
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

#import "TOFileSystemItemURLDictionary.h"

@interface TOFileSystemItemDictionaryTests : XCTestCase

@property (nonatomic, strong) NSString *tempDirectory;
@property (nonatomic, strong) NSURL *baseURL;

@end

@implementation TOFileSystemItemDictionaryTests

- (void)setUp
{
    self.tempDirectory = @"/Users/XD/Documents";
    self.baseURL = [NSURL fileURLWithPath:self.tempDirectory];
}

- (void)testCreation
{
    TOFileSystemItemURLDictionary *dict = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.baseURL];
    XCTAssertNotNil(dict);
}

- (void)testInsertionAndDeletion
{
    TOFileSystemItemURLDictionary *dict = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.baseURL];
    
    // Test first insertion
    NSString *folder1URL = [NSString stringWithFormat:@"%@/Folder1", self.tempDirectory];
    NSURL *url = [NSURL fileURLWithPath:folder1URL].URLByStandardizingPath;
    dict[@"folder1"] = url;
    XCTAssert([url isEqual:dict[@"folder1"]]);
    
    // Test second insertion
    NSString *folder2URL = [NSString stringWithFormat:@"%@/Folder2", self.tempDirectory];
    url = [NSURL fileURLWithPath:folder2URL].URLByStandardizingPath;
    dict[@"folder2"] = url;
    XCTAssert([url isEqual:dict[@"folder2"]]);
    
    // Test deletion
    dict[@"folder1"] = nil;
    XCTAssertNil(dict[@"folder1"]);
}

- (void)testConcurrentReads
{
    TOFileSystemItemURLDictionary *dict = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.baseURL];
    
    NSString *folder1URL = [NSString stringWithFormat:@"%@/Folder1", self.tempDirectory];
    NSURL *url = [NSURL fileURLWithPath:folder1URL].URLByStandardizingPath;
    dict[@"folder1"] = url;
    
    // Check read is working on the main thread
    XCTAssert([url isEqual:dict[@"folder1"]]);
    
    // Create expectation to test concurrent execution
    XCTestExpectation *expectation = [[XCTestExpectation alloc]
                                      initWithDescription:@"Dictionary Reads Succeeded"];
    
    // Create dispatch group so we can call a trigger when both queues finish executing
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    // Kickstart a read on the first thread
    dispatch_queue_t firstQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, firstQueue, ^ {
        XCTAssert([url isEqual:dict[@"folder1"]]);
    });

    // Kickstart a read on the second thread
    dispatch_queue_t secondQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, secondQueue, ^ {
        XCTAssert([url isEqual:dict[@"folder1"]]);
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
    TOFileSystemItemURLDictionary *dict = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.baseURL];
    
    // Create some test URLs to inject
    NSString *folder1URL = [NSString stringWithFormat:@"%@/Folder1", self.tempDirectory];
    NSURL *firstUrl = [NSURL fileURLWithPath:folder1URL].URLByStandardizingPath;
    
    NSString *folder2URL = [NSString stringWithFormat:@"%@/Folder2", self.tempDirectory];
    NSURL *secondUrl = [NSURL fileURLWithPath:folder2URL].URLByStandardizingPath;
    
    // Create expectation to test concurrent execution
    XCTestExpectation *expectation = [[XCTestExpectation alloc]
                                      initWithDescription:@"Dictionary Writes Succeeded"];
    
    // Create dispatch group so we can call a trigger when both queues finish executing
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    // Kickstart a write on the first thread
    dispatch_queue_t firstQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, firstQueue, ^ {
        [dict setItemURL:firstUrl forUUID:@"folder1"];
    });

    // Kickstart a write on the second thread
    dispatch_queue_t secondQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(dispatchGroup, secondQueue, ^ {
        [dict setItemURL:secondUrl forUUID:@"folder2"];
    });

    // Upon completion of both writes, ensure the dictionary contains both values
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_group_notify(dispatchGroup, mainQueue, ^ {
        XCTAssert([firstUrl isEqual:dict[@"folder1"]]);
        XCTAssert([secondUrl isEqual:dict[@"folder2"]]);
        XCTAssertNil([dict itemURLForUUID:@"folder3"]);
        [expectation fulfill];
    });
    
    // Wait for the expectation
    [self waitForExpectations:@[expectation] timeout:1.0f];
}

@end
