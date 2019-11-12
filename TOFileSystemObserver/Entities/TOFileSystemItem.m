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
#import "TOFileSystemPath.h"
#import "NSURL+TOFileSystemUUID.h"

@interface TOFileSystemItem ()

@end

@implementation TOFileSystemItem

#pragma mark - Class Creation -

- (instancetype)initWithItemAtFileURL:(NSURL *)fileURL
{
    if (self = [super init]) {
        [self configureFileSystemUUIDForItemAtURL:fileURL];
        [self refreshFromItemAtURL:fileURL];
    }

    return self;
}

#pragma mark - Update Properties -

- (void)configureFileSystemUUIDForItemAtURL:(NSURL *)url
{
    // Attempt to load any existing UUID
    NSString *uuid = [url to_fileSystemUUID];
    
    // Create a brand new one if it doesn't exist
    if (uuid == nil) {
        self.uuid = [url to_generateUUID];
        return;
    }
    
    // Check to see if the UUID matches the UUID format
    NSString *uuidPattern = @"\\A[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\\Z";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:uuidPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:uuid options:0 range:NSMakeRange(0, uuid.length)];
    
    // A valid regex was found.
    if (range.location != NSNotFound) {
        self.uuid = uuid;
        return;
    }
    
    // If not, generate a new UUID and save it to the file
    self.uuid = [url to_generateUUID];
}

- (BOOL)refreshFromItemAtURL:(NSURL *)url
{
    BOOL hasChanges = NO;
    
    // Copy the name of the item
    NSString *name = [url lastPathComponent];
    if (self.name.length == 0 || ![name isEqualToString:self.name]) {
        self.name = name;
        hasChanges = YES;
    }

    // Check if it is a file or directory
    NSNumber *isDirectory;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    TOFileSystemItemType type = isDirectory.boolValue ? TOFileSystemItemTypeDirectory : TOFileSystemItemTypeFile;
    if (type != self.type) {
        self.type = type;
        hasChanges = YES;
    }

    // Get its creation date
    NSDate *creationDate;
    [url getResourceValue:&creationDate forKey:NSURLCreationDateKey error:nil];
    if (![self.creationDate isEqualToDate:creationDate]) {
        self.creationDate = creationDate;
        hasChanges = YES;
    }
    
    // Get its modification date
    NSDate *modificationDate;
    [url getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
    if (![self.modificationDate isEqualToDate:modificationDate]) {
        self.modificationDate = modificationDate;
        hasChanges = YES;
    }
    
    // If the type is a file, fetch its size
    if (self.type == TOFileSystemItemTypeFile) {
        NSNumber *fileSize;
        [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        if (fileSize.longLongValue != self.size) {
            self.size = fileSize.longLongValue;
            hasChanges = YES;
        }
    }
    
    return hasChanges;
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
        if(self.size != fileSize.longLongValue) { return YES; }
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

//- (NSURL *)absoluteFileURL
//{
//    NSString *filePath = @"";
//
//    // Prepend each parent directory name
//    TOFileSystemItem *item = self;
//    while ((item = item.parentDirectory)) {
//        // Because the directory base points directly to our file in the sandbox,
//        // don't prepend the top level item, as it would then be prepended twice
//        if (item.directoryBase == nil) {
//            filePath = [NSString stringWithFormat:@"%@/%@", item.name, filePath];
//        }
//    }
//
//    // Determine the parent item with the base directory parent
//    item = self;
//    while (item.directoryBase == nil) {
//        item = item.parentDirectory;
//    }
//
//    // Prepend the rest of the directory
//    if (item.directoryBase.filePath.length > 0) {
//        filePath = [NSString stringWithFormat:@"%@/%@", item.directoryBase.filePath, filePath];
//    }
//
//    // Prepend the rest of the Sandbox
//    NSURL *url = [TOFileSystemPath applicationSandboxURL];
//    return [url URLByAppendingPathComponent:filePath];
//}

@end
