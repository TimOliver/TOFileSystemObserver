//
//  TOFileSystemItem.m
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

#import "TOFileSystemItem.h"
#import "TOFileSystemItemList+Private.h"
#import "TOFileSystemPath.h"
#import "TOFileSystemObserver.h"
#import "TOFileSystemPresenter.h"
#import "NSURL+TOFileSystemAttributes.h"
#import "NSURL+TOFileSystemUUID.h"

/** Private interface to expose the file presenter for coordinated writes. */
@interface TOFileSystemObserver (Private)
@property (nonatomic, readonly) TOFileSystemPresenter *fileSystemPresenter;
@end

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
@property (nonatomic, assign, readwrite) NSInteger numberOfSubItems;

@end

@implementation TOFileSystemItem

#pragma mark - Class Creation -

- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL
                   fileSystemObserver:(TOFileSystemObserver *)observer
{
    if (self = [super init]) {
        _fileURL = fileURL;
        _fileSystemObserver = observer;
        
        // If this item represents a deleted file, skip gathering the data
        if (!self.isDeleted) {
            [self configureUUIDForceRefresh:NO];
            [self refreshFromItemAtURL:fileURL];
        }
    }

    return self;
}

#pragma mark - Update Properties -

- (void)configureUUIDForceRefresh:(BOOL)forceRefresh
{
    TOFileSystemPresenter *presenter = self.fileSystemObserver.fileSystemPresenter;
    [presenter performCoordinatedWrite:^{
        self.uuid = [self.fileURL to_makeFileSystemUUIDIfNeeded];
    }];
}

- (BOOL)refreshFromItemAtURL:(NSURL *)url
{
    BOOL hasChanges = NO;
    
    // Copy the new URL to this item
    if (url) {
        self.fileURL = url;
    }
    
    // Copy the name of the item
    NSString *name = [url lastPathComponent];
    if (self.name.length == 0 || ![name isEqualToString:self.name]) {
        self.name = name;
        hasChanges = YES;
    }

    // Check if it is a file or directory
    TOFileSystemItemType type = url.to_isDirectory ? TOFileSystemItemTypeDirectory :
                                                        TOFileSystemItemTypeFile;
    if (type != self.type) {
        self.type = type;
        hasChanges = YES;
    }

    // Get its creation date
    NSDate *creationDate = url.to_creationDate;
    if (![self.creationDate isEqualToDate:creationDate]) {
        self.creationDate = creationDate;
        hasChanges = YES;
    }
    
    // Get its modification date
    NSDate *modificationDate = url.to_modificationDate;
    if (![self.modificationDate isEqualToDate:modificationDate]) {
        self.modificationDate = modificationDate;
        hasChanges = YES;
    }
    
    // Check if it is copying
    self.isCopying = [modificationDate timeIntervalSinceDate:[NSDate date]] > (-1.0f - FLT_EPSILON);
    
    // If the type is a file, fetch its size
    if (self.type == TOFileSystemItemTypeFile) {
        long long fileSize = url.to_size;
        if (fileSize != self.size) {
            self.size = fileSize;
            hasChanges = YES;
        }
    }
    else {
        // Else, it's a directory, count the number of items inside
        NSInteger numberOfChildItems = [self.fileURL to_numberOfSubItems];
        if (self.numberOfSubItems != numberOfChildItems) {
            self.numberOfSubItems = numberOfChildItems;
            hasChanges = YES;
        }
    }
    
    return hasChanges;
}

- (BOOL)isDeleted
{
    return ![[NSFileManager defaultManager] fileExistsAtPath:self.fileURL.path];
}

- (void)regenerateUUID
{
    [self configureUUIDForceRefresh:YES];
}

#pragma mark - Lists -

- (void)refreshWithURL:(nullable NSURL *)itemURL
{
    @synchronized (self) {
        [self refreshFromItemAtURL:itemURL];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.list itemDidRefreshWithUUID:self.uuid];
    });
}

- (void)setList:(TOFileSystemItemList *)list
{
    if (list == _list) { return; }
    
    // Remove this item from the old list
    if (_list) {
        [_list removeItemWithUUID:self.uuid fileURL:self.fileURL];
    }
    
    _list = list;
}

#pragma mark - Equality -

- (BOOL)isEqual:(id)object
{
    if (self == object) { return YES; }
    if (![object isKindOfClass:TOFileSystemItem.class]) { return NO; }
    
    TOFileSystemItem *item = (TOFileSystemItem *)object;
    return [item.uuid isEqualToString:self.uuid];
}

- (NSUInteger)hash
{
    return self.uuid.hash;
}

#pragma mark - Debugging -

- (NSString *)description
{
    NSString *description = @"TOFileSystem Item - \n"
                            @"Name:     %@\n"
                            @"UUID:     %@\n"
                            @"Type:     %@\n"
                            @"Size:     %d\n"
                            @"Created:  %@\n"
                            @"Modified: %@\n";
    
    return [NSString stringWithFormat:description,
            self.name,
            self.uuid,
            self.type != 0 ? @"Folder" : @"File",
            self.size,
            self.creationDate,
            self.modificationDate];
}

@end
