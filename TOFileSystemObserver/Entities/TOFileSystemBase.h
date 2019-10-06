//
//  TOFileSystemBase.h
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

#import "RLMObject.h"

#import "TOFileSystemItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The base item is the entry point for observing a
 directory. It stores the absolute path to our target
 directory in the app sandbox, and holds the array
 graph of all of the items we are observing.
 */
@interface TOFileSystemBase : RLMObject

/** A unique identifier we can use to ensure this object is unique */
@property (nonatomic, strong) NSString *uuid;

/** From the top of the app sandbox, the path to the directory we are targeting. */
@property (nonatomic, copy) NSString *filePath;

/** The subsequent item representing the directory we are targeting. */
@property (nonatomic, strong) TOFileSystemItem *item;

/** If an object already exists in realm, it returns the existing object, else it creates a new one */
+ (instancetype)baseObjectInRealm:(RLMRealm *)realm forItemAtFileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
