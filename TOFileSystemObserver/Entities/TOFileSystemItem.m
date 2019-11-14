//
//  TOFileSystemItem.m
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

#import "TOFileSystemItem.h"
#import "TOFileSystemPath.h"
#import "TOFileSystemObserver.h"
#import "NSURL+TOFileSystemUUID.h"

@interface TOFileSystemItem ()

/** Internal writing overrides for public properties */
@property (nonatomic, strong, readwrite) NSURL *fileURL;
@property (nonatomic, assign, readwrite) TOFileSystemItemType type;
@property (nonatomic, copy,   readwrite) NSString *uuid;
@property (nonatomic, copy,   readwrite) NSString *name;
@property (nonatomic, assign, readwrite) long long size;
@property (nonatomic, strong, readwrite) NSDate *creationDate;
@property (nonatomic, strong, readwrite) NSDate *modificationDate;
@property (nonatomic, assign, readwrite) BOOL isCopying;

@end

@implementation TOFileSystemItem

#pragma mark - Class Creation -

- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL
                   fileSystemObserver:(TOFileSystemObserver *)observer
{
    if (self = [super init]) {
        _fileURL = fileURL;
        _fileSystemObserver = observer;
        _uuid = [fileURL to_makeFileSystemUUIDIfNeeded];
        [self refreshFromItemAtURL:fileURL];
    }

    return self;
}

#pragma mark - Update Properties -

- (BOOL)refreshFromItemAtURL:(NSURL *)url
{
    BOOL hasChanges = NO;
    
    // Copy the name of the item
    NSString *name = [url lastPathComponent];
    if (self.name.length == 0 || ![name isEqualToString:self.name]) {
        self.name = name;
        hasChanges = YES;
    }

    // Check if it is a file or directory
    NSNumber *isDirectory;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    TOFileSystemItemType type = isDirectory.boolValue ? TOFileSystemItemTypeDirectory :
                                                        TOFileSystemItemTypeFile;
    if (type != self.type) {
        self.type = type;
        hasChanges = YES;
    }

    // Get its creation date
    NSDate *creationDate;
    [url getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
    if (![self.creationDate isEqualToDate:creationDate]) {
        self.creationDate = creationDate;
        hasChanges = YES;
    }
    
    // Get its modification date
    NSDate *modificationDate;
    [url getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    if (![self.modificationDate isEqualToDate:modificationDate]) {
        self.modificationDate = modificationDate;
        hasChanges = YES;
    }
    
    // If the type is a file, fetch its size
    if (self.type == TOFileSystemItemTypeFile) {
        NSNumber *fileSize;
        [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        if (fileSize.longLongValue != self.size) {
            self.size = fileSize.longLongValue;
            hasChanges = YES;
        }
    }
    
    return hasChanges;
}

- (BOOL)hasChangesComparedToItemAtURL:(NSURL *)itemURL
{
    // File name
    if (![self.name isEqualToString:itemURL.lastPathComponent]) { return YES; }

    // On-disk UUID
    if (![self.uuid isEqualToString:[itemURL to_fileSystemUUID]]) { return YES; }

    // File type
    NSNumber *isDirectory;
    [itemURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    TOFileSystemItemType type = isDirectory.boolValue ? TOFileSystemItemTypeDirectory : TOFileSystemItemTypeFile;
    if (self.type != type) { return YES; }

    // File size
    if (self.type == TOFileSystemItemTypeFile) {
        NSNumber *fileSize;
        [itemURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        if(self.size != fileSize.longLongValue) { return YES; }
    }

    // Creation date
    NSDate *creationDate;
    [itemURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
    if (![self.creationDate isEqual:creationDate]) { return YES; }

    // Get its modification date
    NSDate *modificationDate;
    [itemURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    if (![self.modificationDate isEqual:modificationDate]) { return YES; }

    return NO;
}

@end
