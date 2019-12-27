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

- (void)testConcurrentWrite
{
    TOFileSystemItemDictionary *dict = [[TOFileSystemItemDictionary alloc] init];
    XCTAssertNotNil(dict);
}

@end
