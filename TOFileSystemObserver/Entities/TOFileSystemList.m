//
//  TOFileSystemList.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 10/11/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemList.h"
#import "TOFileSystemItem.h"
#import "TOFileSystemPath.h"

#import "NSFileManager+TOFileSystemDirectoryEnumerator.h"

@interface TOFileSystemList ()

/** A writeable copy of the location of this directory */
@property (nonatomic, strong, readwrite) NSURL *directoryURL;

/** Store a bookmark to this item in case the user moves it while it's open. */
@property (nonatomic, strong) NSData *bookmarkData;

/** The items array. Internally, it is mutable. */
@property (nonatomic, strong, readwrite) NSMutableArray<TOFileSystemItem *> *items;

@end

@implementation TOFileSystemList

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
{
    if (self = [super init]) {
        _directoryURL = directoryURL;
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    // Create a bookmark object to let us track this URL if the user moves it
    _bookmarkData = [_directoryURL bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                            includingResourceValuesForKeys:nil
                                             relativeToURL:[TOFileSystemPath applicationSandboxURL]
                                                     error:nil];
    
    // Create the file list array
    _items = [NSMutableArray array];
    
    // Build the initial item list
    [self buildItemsList];
}

- (void)buildItemsList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager to_fileSystemEnumeratorForDirectoryAtURL:_directoryURL];
    
    for (NSURL *url in enumerator) {
        TOFileSystemItem *item = [[TOFileSystemItem alloc] initWithItemAtFileURL:url];
        [_items addObject:item];
    }
}

@end
