//
//  TOFileSystemScanOperation.h
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

@class TOFileSystemPresenter;
@class TOFileSystemItemURLDictionary;
@class TOFileSystemScanOperation;

NS_ASSUME_NONNULL_BEGIN

@protocol TOFileSystemScanOperationDelegate <NSObject>

@required

/**
 Called when a new item is discovered is discovered during a scan.
 This is called every time for full-system scans, but will then only be called on items not previously found before
 in subsequent scans.
 */
- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation didDiscoverItemAtURL:(NSURL *)itemURL withUUID:(NSString *)uuid;

/** Called when the properties of an object have been changed (eg, renamed etc) */
- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation itemDidChangeAtURL:(NSURL *)itemURL withUUID:(NSString *)uuid;

/** Called when the file has been moved to another part of the sandbox. */
- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation itemWithUUID:(NSString *)uuid
        didMoveFromURL:(NSURL *)previousURL
                toURL:(NSURL *)url;

/** Called when the file has been deleted. */
- (void)scanOperation:(TOFileSystemScanOperation *)scanOperation didDeleteItemAtURL:(NSURL *)itemURL withUUID:(NSString *)uuid;

/** Called before a full directory scan has started to allow any delegates to prepare in advance. */
- (void)scanOperationWillBeginFullScan:(TOFileSystemScanOperation *)scanOperation;

/** Called when a full directory scan has been completed so we can do some final clean-up. */
- (void)scanOperationDidCompleteFullScan:(TOFileSystemScanOperation *)scanOperation;

@end

/**
 An operation that will either scan all
 child items of a directory, or a list of items
 and update their snapshot if they have changed.
 */
@interface TOFileSystemScanOperation : NSOperation

/** Whether this a complete deep scan or not. */
@property (nonatomic, readonly) BOOL isFullScan;

/** A delegate object that will be called upon any detected change events. */
@property (nonatomic, weak) id<TOFileSystemScanOperationDelegate> delegate;

/** When scanning hierarchies, the numbers deep to scan (-1 is all of them) */
@property (nonatomic, assign) NSInteger subDirectoryLevelLimit;

/** Create a new instance that will scan all of the child items of the provided directory */
- (instancetype)initForFullScanWithDirectoryAtURL:(NSURL *)directoryURL
                                    skippingItems:(NSArray *)skippedItems
                               allItemsDictionary:(nonnull TOFileSystemItemURLDictionary *)allItems
                                    filePresenter:(TOFileSystemPresenter *)filePresenter;

/** Create a new instance that will scan all of the files/folders provided. */
- (instancetype)initForItemScanWithItemURLs:(NSArray<NSURL *> *)itemURLs
                                    baseURL:(NSURL *)baseURL
                              skippingItems:(NSArray *)skippedItems
                         allItemsDictionary:(nonnull TOFileSystemItemURLDictionary *)allItems
                              filePresenter:(TOFileSystemPresenter *)filePresenter;

@end

NS_ASSUME_NONNULL_END
