//
//  TOFileSystemItem.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemItem.h"
#import "TOFileSystemBase.h"
#import "TOFileSystemPath.h"
#import "NSURL+TOFileSystemUUID.h"

@interface TOFileSystemItem ()

@property (readonly) RLMLinkingObjects *parentItems;
@property (readonly) RLMLinkingObjects *parentBases;

@end

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

    // Get its on-disk ID (Only if we're not already persisted)
    if (!self.realm) {
        self.uuid = [fileURL to_fileSystemUUID];
    }

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

- (NSURL *)absoluteFileURL
{
    NSString *filePath = @"";

    // Prepend each parent directory name
    TOFileSystemItem *item = self;
    while ((item = item.parentDirectory)) {
        // Because the directory base points directly to our file in the sandbox,
        // don't prepend the top level item, as it would then be prepended twice
        if (item.directoryBase == nil) {
            filePath = [NSString stringWithFormat:@"%@/%@", item.name, filePath];
        }
    }

    // Determine the parent item with the base directory parent
    item = self;
    while (item.directoryBase == nil) {
        item = item.parentDirectory;
    }

    // Prepend the rest of the directory
    if (item.directoryBase.filePath.length > 0) {
        filePath = [NSString stringWithFormat:@"%@/%@", item.directoryBase.filePath, filePath];
    }

    // Prepend the rest of the Sandbox
    NSURL *url = [TOFileSystemPath applicationSandboxURL];
    return [url URLByAppendingPathComponent:filePath];
}

- (TOFileSystemItem *)parentDirectory
{
    return self.parentItems.firstObject;
}

- (TOFileSystemBase *)directoryBase
{
    return self.parentBases.firstObject;
}

#pragma mark - Realm Properties -

+ (NSString *)primaryKey { return @"uuid"; }

+ (NSArray<NSString *> *)indexedProperties
{
    return @[@"name"];
}

+ (NSDictionary *)linkingObjectsProperties
{
    return @{
        @"parentItems": [RLMPropertyDescriptor descriptorWithClass:TOFileSystemItem.class propertyName:@"childItems"],
        @"parentBases": [RLMPropertyDescriptor descriptorWithClass:TOFileSystemBase.class propertyName:@"item"],
    };
}

// Never automatically include this in the default Realm schema
// as it may get exposed in the app's own Realm files.
+ (BOOL)shouldIncludeInDefaultSchema { return NO; }

@end
