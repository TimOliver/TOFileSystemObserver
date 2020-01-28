//
//  TOFileSystemItemMapTable.m
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

#import "TOFileSystemItemMapTable.h"

@interface TOFileSystemItemMapTable ()

/** The map table to hold the items */
@property (nonatomic, strong) NSMapTable *mapTable;

/** The dispatch queue for synchronzing reads */
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@end

@implementation TOFileSystemItemMapTable

- (instancetype)init
{
    if (self = [super init]) {
        _mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                          valueOptions:NSMapTableWeakMemory];
        _dispatchQueue = dispatch_queue_create("TOFileSystemObserver.itemMapTable", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (void)setItem:(id)object forUUID:(NSString *)uuid
{
    dispatch_barrier_async(self.dispatchQueue, ^{
        [self.mapTable setObject:object forKey:uuid];
    });
}

- (id)itemForUUID:(NSString *)uuid
{
    __block id item = nil;
    dispatch_sync(self.dispatchQueue, ^{
        item = [self.mapTable objectForKey:uuid];
    });
    
    return item;
}

- (void)removeItemForUUID:(NSString *)uuid
{
    dispatch_barrier_async(self.dispatchQueue, ^{
        [self.mapTable removeObjectForKey:uuid];
    });
}

- (void)setObject:(nullable id)object forKeyedSubscript:(nonnull NSString *)key
{
    [self setItem:object forUUID:key];
}

- (nullable id)objectForKeyedSubscript:(NSString *)key
{
    return [self itemForUUID:key];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len
{
    return [_mapTable countByEnumeratingWithState:state
                                       objects:buffer
                                         count:len];
}

@end
