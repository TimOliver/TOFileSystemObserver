//
//  TOFileSystemEnumeratorTests.m
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
#import "NSFileManager+TOFileSystemDirectoryEnumerator.h"

@interface TOFileSystemEnumeratorTests : XCTestCase

@property (nonatomic, strong) NSDirectoryEnumerator<NSURL *> *enumerator;
@property (nonatomic, strong) NSURL *folderURL;

@end

@implementation TOFileSystemEnumeratorTests

- (void)setUp
{
    NSURL *url = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    self.folderURL = [url URLByAppendingPathComponent:@"Folder"];
    [NSFileManager.defaultManager createDirectoryAtURL:self.folderURL withIntermediateDirectories:YES attributes:nil error:nil];
    
    self.enumerator = [NSFileManager.defaultManager to_fileSystemEnumeratorForDirectoryAtURL:url];
}

- (void)tearDown
{
    self.enumerator = nil;
    [NSFileManager.defaultManager removeItemAtURL:self.folderURL error:nil];
}

- (void)testEnumerator
{
    NSInteger i = 0;
    for (NSURL *url in self.enumerator) {
        if (!url) { break; } // Supress unused warning
        i++;
    }
    
    XCTAssertTrue(i > 0);
}

@end
