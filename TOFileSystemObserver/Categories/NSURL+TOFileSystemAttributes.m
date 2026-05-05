//
//  NSURL+TOFileSystemAttributes.m
//
//  Copyright 2019-2022 Timothy Oliver. All rights reserved.
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
#import "TOFileSystemObserverConstants.h"
#include <dirent.h>
#include <sys/stat.h>

@implementation NSURL (TOFileSystemAttributes)

- (BOOL)to_isCopying {
    // When files are still being copied, their
    // modification date is equal to the current device time.
    NSDate * const modificationDate = self.to_modificationDate;
    if (modificationDate == nil) { return NO; }
    return [modificationDate timeIntervalSinceDate:[NSDate date]]
                        > (-kTOFileSystemObserverCopyingTimeDelay - FLT_EPSILON);
}

- (BOOL)to_isDirectory {
    NSNumber *isDirectory;
    [self getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    return isDirectory.boolValue;
}

- (long long)to_size {
    NSNumber *fileSize;
    [self getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
    return fileSize.longLongValue;
}

- (NSDate *)to_creationDate {
    NSDate *creationDate;
    [self getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
    return creationDate;
}

- (NSDate *)to_modificationDate {
    [self removeCachedResourceValueForKey:NSURLContentModificationDateKey];
    NSDate *modificationDate;
    [self getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    return modificationDate;
}

// Decides whether a directory entry should count toward `to_numberOfSubItems`.
// Hidden entries (leading dot) are always skipped. Regular files and directories
// are counted via the d_type fast path. DT_UNKNOWN — which happens on filesystems
// that don't fill d_type, like NFS or FAT — falls back to lstat. Exposed (not
// static) so the DT_UNKNOWN branch can be exercised by unit tests, since it's
// not reachable on APFS where readdir always reports a concrete type.
BOOL TOFileSystemDirEntryIsCountable(const char *parentPath, const struct dirent *entry) {
    if (entry->d_name[0] == '.') { return NO; }
    if (entry->d_type == DT_REG || entry->d_type == DT_DIR) { return YES; }
    if (entry->d_type != DT_UNKNOWN) { return NO; }

    char fullPath[PATH_MAX];
    const int written = snprintf(fullPath, sizeof(fullPath), "%s/%s", parentPath, entry->d_name);
    if (written <= 0 || written >= (int)sizeof(fullPath)) { return NO; }

    struct stat st;
    if (lstat(fullPath, &st) != 0) { return NO; }
    return S_ISREG(st.st_mode) || S_ISDIR(st.st_mode);
}

- (NSInteger)to_numberOfSubItems {
    // Do it using POSIX APIs to avoid needing to load in all of the file names
    const char * const path = [self.path cStringUsingEncoding:NSUTF8StringEncoding];
    DIR * const directory = opendir(path);
    if (directory == NULL) { return 0; }

    NSInteger numberOfItems = 0;
    struct dirent *entry;
    while ((entry = readdir(directory)) != NULL) {
        if (TOFileSystemDirEntryIsCountable(path, entry)) {
            numberOfItems++;
        }
    }
    closedir(directory);

    return numberOfItems;
}

@end
