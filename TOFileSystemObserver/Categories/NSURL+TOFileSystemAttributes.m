//
//  NSURL+TOFileSystemAttributes.m
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

#import "NSURL+TOFileSystemAttributes.h"
#include <dirent.h>

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

- (NSInteger)to_numberOfSubItems
{
    NSInteger numberOfItems = 0;
    DIR *directory;
    struct dirent *entry;

    // Do it using POSIX APIs to avoid needing to load in all of the file names
    const char *path = [self.path cStringUsingEncoding:NSUTF8StringEncoding];
    directory = opendir(path);
    while ((entry = readdir(directory)) != NULL) {
        if (entry->d_name[0] == '.') { continue; }
        if (entry->d_type == DT_REG || entry->d_type == DT_DIR) {
             numberOfItems++;
        }
    }
    closedir(directory);
    
    return numberOfItems;
}

@end
