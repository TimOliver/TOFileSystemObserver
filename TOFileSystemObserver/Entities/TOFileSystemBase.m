//
//  TOFileSystemBase.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

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
