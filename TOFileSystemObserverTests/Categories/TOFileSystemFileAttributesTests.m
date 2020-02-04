//
//  TOFileSystemFileAttributesTests.m
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
#import "NSURL+TOFileSystemAttributes.h"

const NSInteger kTOFileSystemTestFileSize = 3 * 1000000;

@interface TOFileSystemFileAttributesTests : XCTestCase

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSURL *directoryURL;
@property (nonatomic, strong) NSURL *subdirectoryURL;

@end

@implementation TOFileSystemFileAttributesTests

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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.fileURL to_isCopying] == NO) {
            [expectation fulfill];
        }
    });

    [self waitForExpectations:@[expectation] timeout:4.0f];
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
