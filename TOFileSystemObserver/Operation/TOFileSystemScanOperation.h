//
//  TOFileSystemScanOperation.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TOFileSystemItem;
@class RLMRealmConfiguration;

NS_ASSUME_NONNULL_BEGIN
/**
 An operation that scans all items in a directory,
 and adds/updates them in the database as needed.
 */
@interface TOFileSystemScanOperation : NSOperation

/** From the target directory, how many levels down to scan (-1 is all of them). */
@property (nonatomic, assign) NSInteger subDirectoryLevelLimit;

/** Create a new instance based off the item representing the directory where we want to start */
- (instancetype)initWithDirectoryItem:(TOFileSystemItem *)directoryItem
                   realmConfiguration:(RLMRealmConfiguration *)realmConfiguration;

@end

NS_ASSUME_NONNULL_END
