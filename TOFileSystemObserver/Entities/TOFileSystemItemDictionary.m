//
//  TOFileSystemItemDictionary.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2019/12/27.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemItemDictionary.h"

@interface TOFileSystemItemDictionary ()

/** The dictionary that holds all of the item URLs */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURL*> *items;

/** The dispatch queue used to read and write safely to this dictionary. */
@property (nonatomic, strong) dispatch_queue_t itemQueue;

@end

@implementation TOFileSystemItemDictionary

- (instancetype)init
{
    if (self = [super init]) {
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

- (void)setItemURL:(NSURL *)itemURL forUUID:(nullable NSString *)uuid
{
    if (uuid.length == 0) { return; }
    
    dispatch_barrier_async(self.itemQueue, ^{
        self.items[uuid] = itemURL;
    });
}

- (nullable NSURL *)itemURLForUUID:(NSString *)uuid
{
    if (uuid.length == 0) { return nil; }
    
    __block NSURL *itemURL = nil;
    dispatch_sync(self.itemQueue, ^{
        itemURL = self.items[uuid];
    });
    
    return itemURL;
}

- (void)setObject:(nullable id)object forKeyedSubscript:(nonnull NSString *)key
{
    [self setItemURL:object forUUID:key];
}

- (nullable id)objectForKeyedSubscript:(NSString *)key
{
    return [self itemURLForUUID:key];
}

@end
