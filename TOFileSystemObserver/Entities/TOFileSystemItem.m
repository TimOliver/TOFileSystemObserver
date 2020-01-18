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

/** The list that this item belongs to. */
@property (nonatomic, weak, nullable, readwrite) TOFileSystemItemList *list;

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
    NSString *name = [self.fileURL lastPathComponent];
    if (self.name.length == 0 || ![name isEqualToString:self.name]) {
        self.name = name;
        hasChanges = YES;
    }

    // Check if it is a file or directory
    TOFileSystemItemType type = self.fileURL.to_isDirectory ? TOFileSystemItemTypeDirectory :
                                                        TOFileSystemItemTypeFile;
    if (type != self.type) {
        self.type = type;
        hasChanges = YES;
    }

    // Get its creation date
    NSDate *creationDate = self.fileURL.to_creationDate;
    if (![self.creationDate isEqualToDate:creationDate]) {
        self.creationDate = creationDate;
        hasChanges = YES;
    }
    
    // Get its modification date
    NSDate *modificationDate = self.fileURL.to_modificationDate;
    if (![self.modificationDate isEqualToDate:modificationDate]) {
        self.modificationDate = modificationDate;
        hasChanges = YES;
    }
    
    // If the type is a file
    if (self.type == TOFileSystemItemTypeFile) {
        // Fetch the item file size
        long long fileSize = self.fileURL.to_size;
        if (fileSize != self.size) {
            self.size = fileSize;
            hasChanges = YES;
        }
        
        // Check to see if it is copying
        self.isCopying = [modificationDate timeIntervalSinceDate:[NSDate date]] > (-1.0f - FLT_EPSILON);
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

- (BOOL)refreshWithURL:(nullable NSURL *)itemURL
{
    // Perform a re-fetch of all of the properties of the
    // item from disk, and re-populate all of the properties.
    
    // A lock needs to be used as this operation will ideally be done
    // in the background due to how heavy it could potentially be
    BOOL hasChanges = NO;
    @synchronized (self) {
        hasChanges = [self refreshFromItemAtURL:itemURL];
    }
    
    // If it was detected one or more of the properties were
    // different, if the item is a member of a list, inform
    // the list that the UI state of this item will need to be updated.
    if (hasChanges) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            if (self.list == nil) { return; }
            [self.list itemDidRefreshWithUUID:self.uuid];
        }];
    }
    
    return hasChanges;
}

- (void)addToList:(TOFileSystemItemList *)list
{
    self.list = list;
}

- (void)removeFromList
{
    self.list = nil;
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
