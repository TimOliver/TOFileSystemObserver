//
//  TOFileSystemItem.m
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

    // Before we're persisted, ensure the on-disk file
    // has the same UUID as this object
    if (!self.realm) {
        [fileURL to_setFileSystemUUID:self.uuid];
    }

    // Check if it is a file or directory
    NSNumber *isDirectory;
    [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    self.type = isDirectory.boolValue ? TOFileSystemItemTypeDirectory : TOFileSystemItemTypeFile;

    // Get its file size
    if (self.type == TOFileSystemItemTypeFile) {
        NSNumber *fileSize;
        [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
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

- (BOOL)hasChangesComparedToItemAtURL:(NSURL *)itemURL
{
    // File name
    if (![self.name isEqualToString:itemURL.lastPathComponent]) { return YES; }

    // On-disk UUID
    if (![self.uuid isEqualToString:[itemURL to_fileSystemUUID]]) { return YES; }

    // File type
    NSNumber *isDirectory;
    [itemURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    TOFileSystemItemType type = isDirectory.boolValue ? TOFileSystemItemTypeDirectory : TOFileSystemItemTypeFile;
    if (self.type != type) { return YES; }

    // File size
    if (self.type == TOFileSystemItemTypeFile) {
        NSNumber *fileSize;
        [itemURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        if(self.size != fileSize.intValue) { return YES; }
    }

    // Creation date
    NSDate *creationDate;
    [itemURL getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
    if (![self.creationDate isEqual:creationDate]) { return YES; }

    // Get its modification date
    NSDate *modificationDate;
    [itemURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    if (![self.modificationDate isEqual:modificationDate]) { return YES; }

    return NO;
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

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"uuid": [NSUUID UUID].UUIDString};
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
