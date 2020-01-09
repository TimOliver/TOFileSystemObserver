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

- (void)to_setFileSystemUUID:(NSString *)uuid
{
    if (uuid.length > 0 && uuid.length != 36) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"UUID must be 36 characters long!"
                                     userInfo:nil];
    }

    // Determine the file path and destination key
    const char *filePath = [self.path fileSystemRepresentation];
    const char *keyName = kTOFileSystemAttributeKey.UTF8String;

    // Convert the string to a C byte string
    const char *uuidString = [uuid cStringUsingEncoding:NSUTF8StringEncoding];

    // Save it to this file
    setxattr(filePath, keyName, uuidString, strlen(uuidString), 0, 0);
}

- (NSString *)to_generateFileSystemUUID
{
    NSString *uuid = [NSUUID UUID].UUIDString;
    [self to_setFileSystemUUID:uuid];
    return uuid;
}

- (NSString *)to_makeFileSystemUUIDIfNeeded
{
    // Attempt to load any existing UUID that may be there
    NSString *uuid = [self to_fileSystemUUID];
    
    // Create a brand new one if it doesn't exist
    if (uuid == nil) {
        return [self to_generateFileSystemUUID];
    }
    
    // Check to see if the UUID matches the UUID format
    NSString *uuidPattern = @"\\A[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\\Z";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:uuidPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:uuid options:0 range:NSMakeRange(0, uuid.length)];
    
    // A valid regex was found.
    if (range.location != NSNotFound) {
        return uuid;
    }
    
    // If not, generate a new UUID and save it to the file
    return [self to_generateFileSystemUUID];
}

- (nullable NSString *)to_uuidForParentDirectory
{
    return [self.URLByDeletingLastPathComponent to_fileSystemUUID];
}

@end
