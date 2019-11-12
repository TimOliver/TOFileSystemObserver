//
//  TOFileSystemList.h
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

#import <Foundation/Foundation.h>

@class TOFileSystemItem;

/** The different options for ordering item lists */
typedef NS_ENUM(NSInteger, TOFileSystemListOrder) {
    TOFileSystemListOrderAlphanumeric,  // Alphanumeric ordering
    TOFileSystemListOrderDate,          // Creation date
    TOFileSystemListOrderSize           // File size
};

NS_ASSUME_NONNULL_BEGIN

/**
 This class represents a list of files and
 directories located within the directroy that was
 specified.
 
 It is backed by an observer object, that will ensure
 that it is kept up-to-date with any changes that occur on
 the file system.
 */
@interface TOFileSystemList : NSObject

/** The type of ordering of the items. */
@property (nonatomic, assign) TOFileSystemListOrder listOrder;

/** Whether the list is ascending or descending. (Default is ascending). */
@property (nonatomic, assign) BOOL isDescending;

/** An array of all of the items in this directory. */
@property (nonatomic, readonly) NSArray<TOFileSystemItem *> *items;

/** Creates a new instance of a list object with
    the contents of the provided directory. */
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL;

@end

NS_ASSUME_NONNULL_END
