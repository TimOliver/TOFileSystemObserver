//
//  TOFileSystemItem.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemItem.h"
#import "NSURL+TOFileSystemUUID.h"

@implementation TOFileSystemItem

#pragma mark - Class Creation -

- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL
{
    if (self = [super init]) {
        [self updateWithItemAtFileURL:fileURL];
    }

    return self;
}

#pragma mark - Update Properties -

- (void)updateWithItemAtFileURL:(NSURL *)fileURL
{
    // Copy the name of the item
    self.name = [fileURL lastPathComponent];

    // Get its on-disk ID
    self.uuid = [fileURL to_fileSystemUUID];

    // Check if it is a file or directory
    NSNumber *isDirectory;
    [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    self.type = isDirectory.boolValue ? TOFileSystemItemTypeDirectory : TOFileSystemItemTypeFile;

    // Get its file size
    if (self.type == TOFileSystemItemTypeFile) {
        NSNumber *fileSize;
        [fileURL getResourceValue:&fileURL forKey:NSURLFileSizeKey error:nil];
        self.size = fileSize.intValue;
    }

    // Get its creation date
    NSDate *creationDate;
    [fileURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
    self.creationDate = creationDate;

    // Get its modification date
    NSDate *modificationDate;
    [fileURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    self.modificationDate = modificationDate;
}

#pragma mark - Realm Properties -

+ (NSArray<NSString *> *)indexedProperties
{
    return @[@"uuid", @"name"];
}

// Never automatically include this in the default Realm schema
// as it may get exposed in the app's own Realm files.
+ (BOOL)shouldIncludeInDefaultSchema { return NO; }

@end
