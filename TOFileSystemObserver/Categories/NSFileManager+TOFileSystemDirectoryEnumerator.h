//
//  NSDirectoryEnumerator+TOFileSystemDirectoryEnumerator.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 12/11/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A convenience category that creates and pre-configures
 directory enumerators with the parameters we need.
 */
@interface NSFileManager (TOFileSystemDirectoryEnumerator)

/** Create a new directory enumerator with the attributes we're interested configured. */
- (NSDirectoryEnumerator<NSURL *> *)to_fileSystemEnumeratorForDirectoryAtURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
