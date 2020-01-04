//
//  TOFileSystemItemDictionary.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2019/12/27.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemItemDictionary.h"

@interface TOFileSystemItemDictionary ()

/** The base URL against which all other URLs are saved. */
@property (nonatomic, strong) NSURL *baseURL;

/** The dictionary that holds all of the item URLs */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURL*> *items;

/** The dispatch queue used to read and write safely to this dictionary. */
@property (nonatomic, strong) dispatch_queue_t itemQueue;

@end

@implementation TOFileSystemItemDictionary

- (instancetype)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super init]) {
        _baseURL = baseURL.URLByDeletingLastPathComponent.URLByStandardizingPath;
        _items = [NSMutableDictionary dictionary];
        _itemQueue = dispatch_queue_create("TOFileSystemObserver.itemDictionaryQueue",
                                           DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (NSUInteger)count
{
    return self.items.count;
}

- (void)setItemURL:(nullable NSURL *)itemURL forUUID:(nullable NSString *)uuid
{
    if (uuid.length == 0) { return; }
    
    // If the item is nil, remove it from the store
    if (itemURL == nil) {
        dispatch_barrier_async(self.itemQueue, ^{
            [self.items removeObjectForKey:uuid];
        });
        
        return;
    }
    
    // Remove the un-needed absolute path to save memory
    NSString *basePath = self.baseURL.path;
    NSString *itemPath = itemURL.URLByStandardizingPath.path;
    NSString *relativePath = [itemPath stringByReplacingOccurrencesOfString:basePath withString:@""];
    
    // Use dispatch barriers to block all reads when we mutate the dictionary
    dispatch_barrier_async(self.itemQueue, ^{
        self.items[uuid] = [NSURL fileURLWithPath:relativePath];
    });
}

- (nullable NSURL *)itemURLForUUID:(NSString *)uuid
{
    if (uuid.length == 0) { return nil; }
    
    // Use dispatch barriers to allow asynchronouse reading
    __block NSURL *itemURL = nil;
    dispatch_sync(self.itemQueue, ^{
        itemURL = self.items[uuid];
    });
    if (itemURL == nil) { return nil; }
    
    return [self.baseURL URLByAppendingPathComponent:itemURL.path].URLByStandardizingPath;
}

- (nullable NSString *)uuidForItemWithURL:(NSURL *)itemURL
{
    // Convert the item URL to relative
    NSString *basePath = self.baseURL.path;
    NSString *itemPath = itemURL.URLByStandardizingPath.path;
    NSString *relativePath = [itemPath stringByReplacingOccurrencesOfString:basePath withString:@""];
    
    // Look up the URL in the dictionary
    __block NSString *uuid = nil;
    dispatch_sync(self.itemQueue, ^{
        uuid = [self.items allKeysForObject:[NSURL fileURLWithPath:relativePath]].firstObject;
    });
    
    return uuid;
}

- (void)setObject:(nullable id)object forKeyedSubscript:(nonnull NSString *)key
{
    [self setItemURL:object forUUID:key];
}

- (nullable id)objectForKeyedSubscript:(NSString *)key
{
    return [self itemURLForUUID:key];
}

- (NSString *)description
{
    NSString *descriptionString = @"";
    for (NSString *key in self.items.allKeys) {
        descriptionString = [descriptionString stringByAppendingFormat:@"%@ - %@\n", key, self.items[key]];
    }
    
    return descriptionString;
}

@end
