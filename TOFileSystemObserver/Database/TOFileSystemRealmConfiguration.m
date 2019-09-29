//
//  TOFileSystemRealmConfiguration.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemRealmConfiguration.h"

#import "TOFileSystemBase.h"
#import "TOFileSystemItem.h"

@implementation TOFileSystemRealmConfiguration

+ (RLMRealmConfiguration *)fileSystemConfigurationWithFileURL:(NSURL *)fileURL
{
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.fileURL = fileURL;
    configuration.objectClasses = @[TOFileSystemBase.class, TOFileSystemItem.class];
    configuration.deleteRealmIfMigrationNeeded = YES;
    configuration.shouldCompactOnLaunch = ^BOOL(NSUInteger totalBytes, NSUInteger bytesUsed) {
        return (bytesUsed / totalBytes) < 0.9f; // Co
    };
    return configuration;
}

@end
