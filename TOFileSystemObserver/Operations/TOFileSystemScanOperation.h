//
//  TOFileSystemScanOperation.h
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
@class TOFileSystemPresenter;
@class TOFileSystemItemDictionary;
@class RLMRealmConfiguration;

NS_ASSUME_NONNULL_BEGIN
/**
 An operation that will either scan all
 child items of a directory, or a list of items
 and update their snapshot if they have changed.
 */
@interface TOFileSystemScanOperation : NSOperation

/** When scanning hierarchies, the numbers deep to scan (-1 is all of them) */
@property (nonatomic, assign) NSInteger subDirectoryLevelLimit;

/** Create a new instance that will scan all of the child items of the provided directory */
- (instancetype)initWithDirectoryAtURL:(NSURL *)directoryURL
                    allItemsDictionary:(nonnull TOFileSystemItemDictionary *)allItems
                         filePresenter:(TOFileSystemPresenter *)filePresenter;

/** Create a new instance that will scan all of the files/folders provided. */
- (instancetype)initWithItemURLs:(NSArray<NSURL *> *)itemURLs
              allItemsDictionary:(nonnull TOFileSystemItemDictionary *)allItems
                   filePresenter:(TOFileSystemPresenter *)filePresenter;

@end

NS_ASSUME_NONNULL_END
