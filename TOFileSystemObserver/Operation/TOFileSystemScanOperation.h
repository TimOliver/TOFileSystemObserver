//
//  TOFileSystemScanOperation.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 An operation that scans all items in a directory,
 and adds/updates them in the database as needed.
 */
@interface TOFileSystemScanOperation : NSOperation

/** From the target directory, how many levels down to scan (0 is all of them). */
@property (nonatomic, assign) NSInteger directoryLevels;

@end

NS_ASSUME_NONNULL_END
