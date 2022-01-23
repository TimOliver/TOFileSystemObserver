//
//  TOFileSystemChanges.h
//
//  Copyright 2022 Timothy Oliver. All rights reserved.
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

@class TOFileSystemObserver;

NS_ASSUME_NONNULL_BEGIN

/**
 Whenever a file system observer object detects a change
 on disk, it will broadcast an event to any objects that
 have subscribed. The specific changes that were detected
 will be contained in an instance of this class.
 */
NS_SWIFT_NAME(FileSystemChanges)
@interface TOFileSystemChanges : NSObject

/** The observer from where these changes were broadcasted. */
@property (nonatomic, weak, readonly) TOFileSystemObserver *fileSystemObserver;

/**
 Whether the observer is performing the full scan at the start of the session or
 an explict list of files mid-session. If this is true, you might prefer to
 wait to defer any heavy work to the notification that will be sent along when
 this particular scan is complete.
 */
@property (nonatomic, assign, readonly) BOOL isFullScan;

/**
 A dictionary of items that were discovered by the file system observer.
 These are either files that were already on disk and were just discovered for the
 first time in this session, or they are brand new files that were just added by the user.
 
 All files in your app will be discovered at least once during an app session. Use
 this method to compare the files against the current state of your cached information
 to see if it needs to be updated.
 
 The dictionary key is the unique UUID string assigned to the file on disk, and the value
 is the absolute file path URL to the file on disk.
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSURL *> *discoveredItems;

/**
 A dictionary of items that were noted to have had changed during this app session.
 Sorts of changes include the file-name changing, or if it was still being copied and
 had just completed.

 The dictionary key is the unique UUID string assigned to the file on disk, and the value
 is the absolute file path URL to the file on disk.
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSURL *> *modifiedItems;

/**
 A dictionary of items that were noted to have been deleted during this app session.

 The dictionary key is the unique UUID string assigned to the file on disk, and the value
 is the absolute file path URL to the file on disk.
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSURL *> *deletedItems;

/**
 A dictionary of items that were noted to have moved during this app session.

 The dictionary key is the unique UUID string assigned to the file on disk, and the value
 is a 2-element array where the first value is the previous URL and the second is the new URL.
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSArray *> *movedItems;

@end

NS_ASSUME_NONNULL_END
