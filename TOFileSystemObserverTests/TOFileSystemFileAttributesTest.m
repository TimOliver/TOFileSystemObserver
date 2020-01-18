//
//  TOFileSystemFileAttributesTest.m
//  TOFileSystemObserverTests
//
//  Created by Tim Oliver on 2020/01/18.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURL+TOFileSystemAttributes.h"

const NSInteger kTOFileSystemTestFileSize = 3 * 1000000;

@interface TOFileSystemFileAttributesTest : XCTestCase

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSURL *directoryURL;
@property (nonatomic, strong) NSURL *subdirectoryURL;

@end

@implementation TOFileSystemFileAttributesTest

- (void)setUp
{
    //Generate a file we can use to test
    NSURL *tempDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    
    // Create a file
    self.fileURL = [tempDirectory URLByAppendingPathComponent:@"File-1.dat"];
    FILE *file = fopen([self.fileURL.path cStringUsingEncoding:NSUTF8StringEncoding], "wb");
    NSInteger byteCount = kTOFileSystemTestFileSize;
    for (NSInteger j = 0; j < byteCount; j++) {
       fwrite("0", 1, 1, file);
    }
    fclose(file);
    
    // Create the folder
    self.directoryURL = [tempDirectory URLByAppendingPathComponent:@"TestFolder"];
    [NSFileManager.defaultManager createDirectoryAtURL:self.directoryURL withIntermediateDirectories:YES attributes:nil error:nil];

    self.subdirectoryURL = [self.directoryURL URLByAppendingPathComponent:@"SubFolder"];
    [NSFileManager.defaultManager createDirectoryAtURL:self.subdirectoryURL withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown
{
    [NSFileManager.defaultManager removeItemAtURL:self.fileURL error:nil];
}

- (void)testCopying
{
    // Since this is executed right after creation, this will be true
    XCTAssertTrue([self.fileURL to_isCopying]);
    
    // Wait a second, and it should transition to "completed'
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Copying File Completed"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.fileURL to_isCopying] == NO) {
            [expectation fulfill];
        }
    });

    [self waitForExpectations:@[expectation] timeout:3.0f];
}

- (void)testIsDirectory
{
    XCTAssertTrue(self.directoryURL.to_isDirectory);
}

- (void)testSize
{
    XCTAssertTrue(self.fileURL.to_size == kTOFileSystemTestFileSize);
}

- (void)testSubItemCount
{
    XCTAssertTrue(self.directoryURL.to_numberOfSubItems == 1);
}

- (void)testCreationDate
{
    XCTAssertNotNil(self.fileURL.to_creationDate);
}

- (void)testModificationDate
{
    XCTAssertNotNil(self.fileURL.to_modificationDate);
}

@end
