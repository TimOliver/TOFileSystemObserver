//
//  NSURL+TOFileSystemAttributes.h
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
 A convenience wrapper for fetching specific attributes
 about the item on disk that this URL represents
 */
@interface NSURL (TOFileSystemAttributes)

/** Whether the file is currently being copied or not. */
@property (nonatomic, readonly) BOOL to_isCopying;

/** Whether the item is a directory or file. */
@property (nonatomic, readonly) BOOL to_isDirectory;

/** The file size of the item (0 for directories) */
@property (nonatomic, readonly) long long to_size;

/** The creation date of the item. */
@property (nonatomic, readonly) NSDate *to_creationDate;

/** The modification date of the item. */
@property (nonatomic, readonly) NSDate *to_modificationDate;

/** The number of sub-items in this directory. */
@property (nonatomic, readonly) NSInteger to_numberOfSubItems;

@end

NS_ASSUME_NONNULL_END
