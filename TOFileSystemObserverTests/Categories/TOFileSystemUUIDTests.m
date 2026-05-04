//
//  TOFileSystemUUIDTests.m
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
#import "NSURL+TOFileSystemUUID.h"

@interface TOFileSystemUUIDTests : XCTestCase
@property (nonatomic, strong) NSURL *itemURL;
@property (nonatomic, strong) NSURL *childItemURL;
@end

@implementation TOFileSystemUUIDTests

- (void)setUp {
    // Create a temp folder to test
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Folder"];
    self.itemURL = [NSURL fileURLWithPath:filePath];
    [NSFileManager.defaultManager createDirectoryAtURL:self.itemURL
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];
    
    // Create a temp child folder
    self.childItemURL = [self.itemURL URLByAppendingPathComponent:@"ChildFolder"];
    [NSFileManager.defaultManager createDirectoryAtURL:self.childItemURL
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];
}

- (void)tearDown {
    // Delete the folder so we can start fresh
    [[NSFileManager defaultManager] removeItemAtURL:self.itemURL error:nil];
}

- (void)testCreatingUUID
{
    // Confirm it's nil at the start
    XCTAssert([self.itemURL to_fileSystemUUID].length == 0);
    
    // Generate a UUID for the item
    NSString *uuid = [self.itemURL to_generateFileSystemUUID];
    
    // Compare to the one on disk now
    XCTAssert([[self.itemURL to_fileSystemUUID] isEqualToString:uuid]);
}

- (void)testRepairingUUID
{
    // Confirm it's nil at the start
    XCTAssertNil([self.itemURL to_fileSystemUUID]);

    // Set a non-uuid value to the file
    [self.itemURL to_setFileSystemUUID:@"000000000000000000000000000000000000"];

    // Regenerate a new uuid
    NSString *newUUID = [self.itemURL to_fileSystemUUID];

    // Sanity check it's not matching the dummy
    XCTAssertNil(newUUID);
}

- (void)testSetUUIDReturnsYesOnSuccess
{
    NSString *uuid = [NSUUID UUID].UUIDString;
    XCTAssertTrue([self.itemURL to_setFileSystemUUID:uuid]);
    XCTAssertEqualObjects([self.itemURL to_fileSystemUUID], uuid);
}

- (void)testSetUUIDRejectsNilAndEmptyWithoutCrashing
{
    // Passing through a typed variable so the compiler doesn't reject the literal
    // nil against the nonnull-annotated parameter.
    NSString *nilUUID = nil;
    XCTAssertFalse([self.itemURL to_setFileSystemUUID:nilUUID]);
    XCTAssertFalse([self.itemURL to_setFileSystemUUID:@""]);
    XCTAssertNil([self.itemURL to_fileSystemUUID]);
}

- (void)testSetUUIDThrowsForInvalidLength
{
    XCTAssertThrows([self.itemURL to_setFileSystemUUID:@"too-short"]);
}

- (void)testGenerateUUIDReturnsNilWhenWriteFails
{
    // Pointing at a path that doesn't exist makes setxattr fail (ENOENT), so
    // the generator should propagate nil rather than report a phantom UUID.
    NSURL *missingURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"missing-for-uuid-test"]];
    XCTAssertNil([missingURL to_generateFileSystemUUID]);
}

@end
