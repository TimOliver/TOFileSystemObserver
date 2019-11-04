//
//  TOFileSystemItem.h
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

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@class TOFileSystemBase;

// The different types of items stored in the file system
typedef NS_ENUM(NSInteger, TOFileSystemItemType) {
    TOFileSystemItemTypeFile, // A standard file
    TOFileSystemItemTypeDirectory // A folder
};

// Forward declaration so that the item may be used in an array
@class TOFileSystemItem;
RLM_ARRAY_TYPE(TOFileSystemItem)

NS_ASSUME_NONNULL_BEGIN

/**
 A Realm managed object model used to track
 a snapshot copy of the current file system.

 This is then compared with the current file system
 to determine when something has changed.
 */
@interface TOFileSystemItem : RLMObject

/** The type of the item (either a file or folder) */
@property (nonatomic, assign) TOFileSystemItemType type;

/** The unique ID number assigned to this item by the file system. */
@property (nonatomic, copy) NSString *uuid;

/** The name on disk of the item. */
@property (nonatomic, copy) NSString *name;

/** The size (in bytes) of this item. (0 for directories). */
@property (nonatomic, assign) long long size;

/** The creation date of the item. */
@property (nonatomic, strong) NSDate *creationDate;

/** The last modification date of the item. */
@property (nonatomic, strong) NSDate *modificationDate;

/** Whether the item is still being copied into the app container. */
@property (nonatomic, assign) BOOL isCopying;

/** If the file is no longer on disk, this flag is used to confirm if it was moved or deleted. */
@property (nonatomic, assign) BOOL isPendingDeletion;

/** If a directory, the child items inside it. */
@property (nonatomic, strong, nullable) RLMArray<TOFileSystemItem *><TOFileSystemItem> *childItems;

/** The parent directory, if any that this item belongs to. */
@property (readonly, nullable) TOFileSystemItem *parentDirectory;

/** Where applicable, the base object at the very top level */
@property (readonly, nullable) TOFileSystemBase *directoryBase;

/** Generates an absolute URL path to this item. */
//@property (nonatomic, readonly) NSURL *absoluteFileURL;

/** Fetches a file item from the supplied Realm. Returns nil if it can't be found. */
+ (nullable TOFileSystemItem *)itemInRealm:(RLMRealm *)realm forItemAtURL:(NSURL *)itemURL;

/** Create a new, unmanaged instance to represent the file at the given URL. */
- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL;

/** Refresh the properties of the item against the file at the given URL. */
- (void)updateWithItemAtFileURL:(NSURL *)fileURL;

/** Compares the meta-data in the DB against the file on disk*/
- (BOOL)hasChangesComparedToItemAtURL:(NSURL *)itemURL;

@end

NS_ASSUME_NONNULL_END
