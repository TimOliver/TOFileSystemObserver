//
//  NSURL+TOFileSystemAttributes.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2020/01/03.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import "NSURL+TOFileSystemAttributes.h"

@implementation NSURL (TOFileSystemAttributes)

- (BOOL)to_isCopying
{
    // When files are still being copied, their
    // modification date is equal to the current device time.
    return [self.to_modificationDate timeIntervalSinceDate:[NSDate date]] > (-1.0f - FLT_EPSILON);
}

- (BOOL)to_isDirectory
{
    NSNumber *isDirectory;
    [self getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    return isDirectory.boolValue;
}

- (long long)to_size
{
    NSNumber *fileSize;
    [self getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
    return fileSize.longLongValue;
}

- (NSDate *)to_creationDate
{
    NSDate *creationDate;
    [self getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
    return creationDate;
}

- (NSDate *)to_modificationDate
{
    NSDate *modificationDate;
    [self getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    return modificationDate;
}

@end
