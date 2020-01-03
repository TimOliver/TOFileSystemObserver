//
//  NSURL+TOFileSystemAttributes.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2020/01/03.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A convenience wrapper for fetching specific attributes
 about the item on disk that this URL represents
 */
@interface NSURL (TOFileSystemAttributes)

/** Whether the item is a directory or file. */
@property (nonatomic, readonly) BOOL to_isDirectory;

/** The file size of the item (0 for directories) */
@property (nonatomic, readonly) long long to_size;

/** The creation date of the item. */
@property (nonatomic, readonly) NSDate *to_creationDate;

/** The modification date of the item. */
@property (nonatomic, readonly) NSDate *to_modificationDate;

@end

NS_ASSUME_NONNULL_END
