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

@end

@implementation TOFileSystemItemURLDictionaryTests

- (void)setUp
{
    self.baseURL = [TOFileSystemPath documentsDirectoryURL];
    self.dictionary = [[TOFileSystemItemURLDictionary alloc] initWithBaseURL:self.baseURL];
}

- (void)tearDown
{
    self.baseURL = nil;
    self.dictionary = nil;
}

- (void)testInsertingAndRetrieving
{
    NSURL *testURL = [self.baseURL URLByAppendingPathComponent:@"Folder"];
    NSString *uuid = @"f2a5bc6d-0eab-4970-8650-8629fdc3a866";
    
    // Insert
    [self.dictionary setItemURL:testURL forUUID:uuid];

    // Verify it was inserted correctly
    XCTAssertEqual(self.dictionary.count, 1);
}

@end
