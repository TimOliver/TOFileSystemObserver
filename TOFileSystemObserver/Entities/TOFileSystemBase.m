//
//  TOFileSystemBase.m
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

#import "TOFileSystemBase.h"

#import "TOFileSystemPath.h"

@implementation TOFileSystemBase

+ (instancetype)baseObjectInRealm:(RLMRealm *)realm forItemAtFileURL:(NSURL *)fileURL
{
    NSString *targetDirectoryPath = [TOFileSystemPath relativePathWithPath:fileURL];

    TOFileSystemBase *baseObject = nil;
    @autoreleasepool {
        // Query for the base object and return it if we already have one
        baseObject = [TOFileSystemBase objectsInRealm:realm where:@"filePath == %@", targetDirectoryPath].firstObject;
        if (baseObject) { return baseObject; }

        // Create a new base object
        baseObject = [[TOFileSystemBase alloc] init];
        baseObject.filePath = targetDirectoryPath;
        baseObject.item = [[TOFileSystemItem alloc] initWithItemAtFileURL:fileURL];

        // Add it to Realm
        [realm transactionWithBlock:^{
            [realm addObject:baseObject];
        }];
    }

    // Return the object
    return baseObject;
}

#pragma mark - Realm Properties -

+ (NSString *)primaryKey { return @"uuid"; }

+ (NSArray<NSString *> *)indexedProperties
{
    return @[@"filePath"];
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"uuid" : [NSUUID UUID].UUIDString };
}

// Never automatically include this in the default Realm schema
// as it may get exposed in the app's own Realm files.
+ (BOOL)shouldIncludeInDefaultSchema { return NO; }

@end
