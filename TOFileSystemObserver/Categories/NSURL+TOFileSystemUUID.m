//
//  NSURL+TOFileSystemUUID.m
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
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

#import "NSURL+TOFileSystemUUID.h"

#import <sys/xattr.h>

static NSString * const kTOFileSystemAttributeKey = @"dev.tim.fileSystemObserver.UUID";

@implementation NSURL (TOFileSystemUUID)

- (NSString *)to_fileSystemUUID
{
    const char *filePath = [self.path fileSystemRepresentation];
    const char *keyName = kTOFileSystemAttributeKey.UTF8String;

    // Allocate a buffer for the value (UUID values are always 36 characters)
    char value[36];

    // Fetch the value from disk
    getxattr(filePath, keyName, value, 36, 0, 0);

    // Convert to a string, and return if successful
    NSString *uuid = [[NSString alloc] initWithBytes:value length:36 encoding:NSUTF8StringEncoding];
    if (uuid.length > 0) {
        return uuid;
    }

    return nil;
}

- (NSString *)to_generateUUID
{
    const char *filePath = [self.path fileSystemRepresentation];
    const char *keyName = kTOFileSystemAttributeKey.UTF8String;

    // Generate a new UUID
    NSString *uuid = [NSUUID UUID].UUIDString;
    const char *uuidString = [uuid cStringUsingEncoding:NSUTF8StringEncoding];

    // Save it to this file
    setxattr(filePath, keyName, uuidString, strlen(uuidString), 0, 0);

    return uuid;
}



@end
