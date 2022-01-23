//
//  TOFileSystemItemMapTable.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A thread-safe wrapper for the NSMapTable objects
 used to store re-usable instances of item and list
 objects.
 */
@interface TOFileSystemItemMapTable : NSObject<NSFastEnumeration>

@property (nonatomic, readonly) NSInteger count;

- (void)setItem:(id)object forUUID:(NSString *)uuid;
- (id)itemForUUID:(NSString *)uuid;
- (void)removeItemForUUID:(NSString *)uuid;

/** Implementations for allowing dictionary style literal syntax. */
- (void)setObject:(nullable id)object forKeyedSubscript:(nonnull NSString *)key;
- (nullable id)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
