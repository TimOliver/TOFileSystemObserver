//
//  TOFileSystemItemDictionary.m
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

#import "TOFileSystemItemURLDictionary.h"

@interface TOFileSystemItemURLDictionary ()

/** The base URL against which all other URLs are saved. */
@property (nonatomic, strong) NSURL *baseURL;

/** The dictionary that holds all of the item URLs */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURL*> *uuidItems;

/** A reverse dictionary tha stores UUIDs for URLs */
@property (nonatomic, strong) NSMutableDictionary<NSURL*, NSString *> *urlItems;

/** The dispatch queue used to read and write safely to this dictionary. */
@property (nonatomic, strong) dispatch_queue_t itemQueue;

@end

@implementation TOFileSystemItemURLDictionary

#pragma mark - Class Creation -

- (instancetype)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super init]) {
        _baseURL    = baseURL.URLByDeletingLastPathComponent.URLByStandardizingPath;
        _uuidItems  = [NSMutableDictionary dictionary];
        _urlItems   = [NSMutableDictionary dictionary];
        _itemQueue  = dispatch_queue_create("TOFileSystemObserver.itemDictionaryQueue",
                                                            DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (NSUInteger)count
{
    __block NSInteger count = 0;
    dispatch_sync(self.itemQueue, ^{
        count = self.uuidItems.count;
    });
    
    return count;
}

- (void)setItemURL:(nullable NSURL *)itemURL forUUID:(nullable NSString *)uuid
{
    if (uuid.length == 0) { return; }
    
    // If the item is nil, remove it from the store
    if (itemURL == nil) {
        dispatch_barrier_async(self.itemQueue, ^{
            NSURL *url = self.uuidItems[uuid];
            [self.urlItems removeObjectForKey:url];
            [self.uuidItems removeObjectForKey:uuid];
        });
        return;
    }
    
    // Use dispatch barriers to block all reads when we mutate the dictionary
    dispatch_barrier_async(self.itemQueue, ^{
        // Purge the previously saved entries as they may be stale
        NSURL *savedURL = self.uuidItems[uuid];
        NSString *savedUUID = self.urlItems[savedURL];
        if (savedUUID) { [self.uuidItems removeObjectForKey:savedUUID]; }
        if (savedURL) { [self.urlItems removeObjectForKey:savedURL]; }
        
        // Remove the un-needed absolute path to save memory
        NSURL *url = [self relativeURLForURL:itemURL];
        self.uuidItems[uuid] = url;
        self.urlItems[url] = uuid;
    });
}

- (nullable NSURL *)itemURLForUUID:(NSString *)uuid
{
    if (uuid.length == 0) { return nil; }
    
    // Use dispatch barriers to allow asynchronouse reading
    __block NSURL *itemURL = nil;
    dispatch_sync(self.itemQueue, ^{
        itemURL = self.uuidItems[uuid];
    });
    if (itemURL == nil) { return nil; }
    
    return [self.baseURL URLByAppendingPathComponent:itemURL.path].URLByStandardizingPath;
}

- (nullable NSString *)uuidForItemWithURL:(NSURL *)itemURL
{
    // Convert the item URL to relative
    NSURL *url = [self relativeURLForURL:itemURL];
    
    // Look up the URL in the dictionary
    __block NSString *uuid = nil;
    dispatch_sync(self.itemQueue, ^{
        uuid = self.urlItems[url];
    });
    
    return uuid;
}

- (void)setObject:(nullable id)object forKeyedSubscript:(nonnull NSString *)key
{
    [self setItemURL:object forUUID:key];
}

- (void)removeItemURLForUUID:(NSString *)uuid
{
    if (uuid == nil) { return; }
    
    dispatch_barrier_async(self.itemQueue, ^{
        NSURL *url = self.uuidItems[uuid];
        if (url == nil) { return; }
        [self.urlItems removeObjectForKey:url];
        [self.uuidItems removeObjectForKey:uuid];
    });
}

- (void)removeAllItems
{
    dispatch_barrier_async(self.itemQueue, ^{
        [self.urlItems removeAllObjects];
        [self.uuidItems removeAllObjects];
    });
}

- (nullable id)objectForKeyedSubscript:(NSString *)key
{
    return [self itemURLForUUID:key];
}

#pragma mark - URL Conversion -

- (NSURL *)relativeURLForURL:(NSURL *)url
{
    NSString *basePath = self.baseURL.path;
    NSString *itemPath = url.URLByStandardizingPath.path;
    NSString *relativePath = [itemPath stringByReplacingOccurrencesOfString:basePath withString:@""];
    return [NSURL fileURLWithPath:relativePath];
}

#pragma mark - Debugging -

- (NSString *)description
{
    NSString *descriptionString = @"";
    for (NSString *key in self.uuidItems.allKeys) {
        descriptionString = [descriptionString stringByAppendingFormat:@"%@ - %@\n", key, self.uuidItems[key]];
    }
    
    return descriptionString;
}

@end
