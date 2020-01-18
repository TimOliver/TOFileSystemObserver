//
//  TOFileSystemEnumeratorTests.m
//  TOFileSystemObserverTests
//
//  Created by Tim Oliver on 2020/01/19.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

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
