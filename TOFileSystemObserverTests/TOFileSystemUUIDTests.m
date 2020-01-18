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
    XCTAssertNil([self.itemURL to_fileSystemUUID]);
    
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
    NSString *dummyUUID = @"000000000000000000000000000000000000";
    [self.itemURL to_setFileSystemUUID:@"000000000000000000000000000000000000"];
    
    // Regenerate a new uuid
    NSString *newUUID = [self.itemURL to_makeFileSystemUUIDIfNeeded];
    
    // Sanity check it's not matching the dummy
    XCTAssert([newUUID isEqualToString:dummyUUID] == NO);
    
    // Confirm the value on disk is the one we were given
    XCTAssert([[self.itemURL to_fileSystemUUID] isEqualToString:newUUID]);
}

- (void)testParentUUIDAccess
{
    // Confirm it's nil at the start
    XCTAssertNil([self.itemURL to_fileSystemUUID]);
    
    // Generate a UUID for the parent
    NSString *uuid = [self.itemURL to_makeFileSystemUUIDIfNeeded];
    
    // Confirm the child can see the parent UUID
    XCTAssert([[self.childItemURL to_uuidForParentDirectory] isEqualToString:uuid]);
}

@end
