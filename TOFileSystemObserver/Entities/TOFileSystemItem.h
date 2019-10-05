//
//  TOFileSystemItem.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

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

/** If a directory, the child items inside it. */
@property (nonatomic, strong, nullable) RLMArray<TOFileSystemItem *><TOFileSystemItem> *childItems;

/** The parent directory, if any that this item belongs to. */
@property (readonly, nullable) TOFileSystemItem *parentDirectory;

/** Where applicable, the base object at the very top level */
@property (readonly, nullable) TOFileSystemBase *directoryBase;

/** Generates an absolute URL path to this item. */
@property (nonatomic, readonly) NSURL *absoluteFileURL;

/** Create a new instance to represent the file at the given URL. */
- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL;

/** Refresh the properties of the item against the file at the given URL. */
- (void)updateWithItemAtFileURL:(NSURL *)fileURL;

/** Compares the meta-data in the DB against the file on disk*/
- (BOOL)hasChangesComparedToItemAtURL:(NSURL *)itemURL;

@end

NS_ASSUME_NONNULL_END
