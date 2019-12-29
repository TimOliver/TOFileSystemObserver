//
//  NSURL+TOFileSystemStandardized.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2019/12/29.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (TOFileSystemStandardized)

/**
 Returns a standardized version of the file path,
 suitable for string comparisons and converting between
 absolute and relative.
 */
@property (nonatomic, readonly) NSURL *to_standardizedURL;

@end

NS_ASSUME_NONNULL_END
