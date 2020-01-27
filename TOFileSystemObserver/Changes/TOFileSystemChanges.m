//
//  TOFileSystemChanges.m
//
//  Copyright 2020 Timothy Oliver. All rights reserved.
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

#import "TOFileSystemChanges.h"

@interface TOFileSystemChanges ()

@property (nonatomic, weak, readwrite) TOFileSystemObserver *fileSystemObserver;
@property (nonatomic, strong, readwrite) NSMutableDictionary *discoveredItems;
@property (nonatomic, strong, readwrite) NSMutableDictionary *modifiedItems;
@property (nonatomic, strong, readwrite) NSMutableDictionary *deletedItems;
@property (nonatomic, strong, readwrite) NSMutableDictionary *movedItems;

@end

@implementation TOFileSystemChanges

- (instancetype)initWithFileSystemObserver:(TOFileSystemObserver *)fileSystemObserver
{
    if (self = [super init]) {
        _fileSystemObserver = fileSystemObserver;
    }
    return self;
}

- (void)addDiscoveredItemWithUUID:(NSString *)uuid fileURL:(NSURL *)fileURL
{
    if (_discoveredItems == nil) {
        _discoveredItems = [NSMutableDictionary dictionary];
    }
    _discoveredItems[uuid] = fileURL;
}

- (void)addModifiedItemWithUUID:(NSString *)uuid fileURL:(NSURL *)fileURL
{
    if (_modifiedItems == nil) {
        _modifiedItems = [NSMutableDictionary dictionary];
    }
    _modifiedItems[uuid] = fileURL;
}

- (void)addDeletedItemWithUUID:(NSString *)uuid fileURL:(NSURL *)fileURL
{
    if (_deletedItems == nil) {
        _deletedItems = [NSMutableDictionary dictionary];
    }
    _deletedItems[uuid] = fileURL;
}

- (void)addMovedItemWithUUID:(NSString *)uuid
                  oldFileURL:(NSURL *)oldFileURL
                  newFileURL:(NSURL *)newFileURL
{
    if (_movedItems == nil) {
        _movedItems = [NSMutableDictionary dictionary];
    }
    _movedItems[uuid] = @[oldFileURL, newFileURL];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Discovered items: %@\nModified items: %@\nDeleted Items: %@\nMoved items: %@\n",
            self.discoveredItems, self.modifiedItems, self.deletedItems, self.movedItems];
}

@end
