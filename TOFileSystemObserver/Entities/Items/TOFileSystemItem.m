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
#import "TOFileSystemObserverConstants.h"

#import <os/lock.h>
#import <pthread/pthread.h>

/** Private interface to expose the file presenter for coordinated writes. */
@interface TOFileSystemObserver ()
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

/** Thread safe locks */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
@property (nonatomic, assign) os_unfair_lock unfairLock;
@property (nonatomic, assign) pthread_mutex_t pthreadMutexLock;
#pragma clang diagnostic pop

@end

@implementation TOFileSystemItem

#pragma mark - Class Creation -

- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL
                   fileSystemObserver:(TOFileSystemObserver *)observer
{
    if (self = [super init]) {
        _fileURL = fileURL;
        _fileSystemObserver = observer;
        
        // Initialize the lock
        if (@available(iOS 10.0, *)) {
            self.unfairLock = OS_UNFAIR_LOCK_INIT;
        } else {
            pthread_mutex_init(&_pthreadMutexLock, NULL);
        }
        
        // If this item represents a deleted file, skip gathering the data
        if (!self.isDeleted) {
            [self performWithLock:^{
                [self configureUUIDForceRefresh:NO];
                [self refreshFromItemAtURL:fileURL];
            }];
        }
    }

    return self;
}

#pragma mark - Update Properties -

- (void)configureUUIDForceRefresh:(BOOL)forceRefresh
{
    TOFileSystemPresenter *presenter = self.fileSystemObserver.fileSystemPresenter;
    _uuid = [presenter uuidForItemAtURL:_fileURL];
}

- (BOOL)refreshFromItemAtURL:(NSURL *)url
{
    BOOL hasChanges = NO;
    
    // Copy the new URL to this item
    if (url) {
        _fileURL = url;
    }
    
    // Copy the name of the item
    NSString *name = [_fileURL lastPathComponent];
    if (_name.length == 0 || ![name isEqualToString:_name]) {
        _name = name;
        hasChanges = YES;
    }

    // Check if it is a file or directory
    TOFileSystemItemType type = _fileURL.to_isDirectory ? TOFileSystemItemTypeDirectory :
                                                        TOFileSystemItemTypeFile;
    if (type != _type) {
        _type = type;
        hasChanges = YES;
    }

    // Get its creation date
    NSDate *creationDate = _fileURL.to_creationDate;
    if (![_creationDate isEqualToDate:creationDate]) {
        _creationDate = creationDate;
        hasChanges = YES;
    }
    
    // Get its modification date
    NSDate *modificationDate = _fileURL.to_modificationDate;
    if (![_modificationDate isEqualToDate:modificationDate]) {
        _modificationDate = modificationDate;
        hasChanges = YES;
    }
    
    // If the type is a file
    if (_type == TOFileSystemItemTypeFile) {
        // Fetch the item file size
        long long fileSize = _fileURL.to_size;
        if (fileSize != _size) {
            _size = fileSize;
            hasChanges = YES;
        }
        
        // Check to see if it is copying
        BOOL isCopying = _fileURL.to_isCopying;
        if (isCopying != _isCopying) {
            _isCopying = isCopying;
            hasChanges = YES;
        }
    }
    else {
        // Else, it's a directory, count the number of items inside
        NSInteger numberOfChildItems = [_fileURL to_numberOfSubItems];
        if (_numberOfSubItems != numberOfChildItems) {
            _numberOfSubItems = numberOfChildItems;
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
    [self performWithLock:^{
        [self configureUUIDForceRefresh:YES];
    }];
}

#pragma mark - Lists -

- (BOOL)refreshWithURL:(nullable NSURL *)itemURL
{
    // Perform a re-fetch of all of the properties of the
    // item from disk, and re-populate all of the properties.
    
    // A lock needs to be used as this operation will ideally be done
    // in the background due to how heavy it could potentially be
    __block BOOL hasChanges = NO;
    [self performWithLock:^{
        hasChanges = [self refreshFromItemAtURL:itemURL];
    }];
    
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

#pragma mark - Thread-Safe Accessors -

// To ensure thread safety, fetch the value of an object
// on the barrier queue
- (id)fetchValueForObject:(NSString *)objectName
{
    __block id objectValue = nil;
    [self performWithLock:^{
        objectValue = [self valueForKey:objectName];
    }];
    
    return objectValue;
}

- (long long)fetchValueForInteger:(NSString *)integerName
{
    __block long long intValue = 0;
    [self performWithLock:^{
        intValue = [[self valueForKey:integerName] longLongValue];
    }];
    
    return intValue;
}

- (NSURL *)fileURL { return (NSURL *)[self fetchValueForObject:@"_fileURL"]; }
- (NSString *)uuid { return (NSString *)[self fetchValueForObject:@"_uuid"]; }
- (NSString *)name { return (NSString *)[self fetchValueForObject:@"_name"]; }
- (long long)size { return (long long)[self fetchValueForInteger:@"_size"]; }
- (NSDate *)creationDate { return (NSDate *)[self fetchValueForObject:@"_creationDate"]; }
- (NSDate *)modificationDate { return (NSDate *)[self fetchValueForObject:@"_modificationDate"]; }
- (BOOL)isCopying { return (BOOL)[self fetchValueForInteger:@"_isCopying"]; }
- (NSInteger)numberOfSubItems { return (NSInteger)[self fetchValueForInteger:@"_numberOfSubItems"]; }

#pragma mark - Thread Safe Access -

- (void)performWithLock:(void (^)(void))block;
{
    // Lock the current thread
    if (@available(iOS 10.0, *)) {
        os_unfair_lock_lock(&_unfairLock);
    } else {
        pthread_mutex_lock(&_pthreadMutexLock);
    }

    block();

    // Unlock the thread
    if (@available(iOS 10.0, *)) {
        os_unfair_lock_unlock(&_unfairLock);
    } else {
        pthread_mutex_unlock(&_pthreadMutexLock);
    }
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
