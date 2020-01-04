//
//  NSDirectoryEnumerator+TOFileSystemDirectoryEnumerator.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 12/11/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "NSFileManager+TOFileSystemDirectoryEnumerator.h"

@implementation NSFileManager (TOFileSystemDirectoryEnumerator)

- (NSDirectoryEnumerator<NSURL *> *)to_fileSystemEnumeratorForDirectoryAtURL:(NSURL *)url
{
    // Set the keys for the properties we wish to capture
    NSArray *keys = @[NSURLIsDirectoryKey,
                      NSURLFileSizeKey,
                      NSURLCreationDateKey,
                      NSURLContentModificationDateKey];

    // Set the flags for the enumerator
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles |
                                            NSDirectoryEnumerationSkipsSubdirectoryDescendants;

    // Create the enumerator
    NSDirectoryEnumerator<NSURL *> *urlEnumerator = [self enumeratorAtURL:url
                                               includingPropertiesForKeys:keys
                                                                  options:options
                                                             errorHandler:nil];
    return urlEnumerator;
}

@end
