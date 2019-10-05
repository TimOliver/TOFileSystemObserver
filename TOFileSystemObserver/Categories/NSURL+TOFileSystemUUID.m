//
//  NSURL+TOFileSystemUUID.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 30/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

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
