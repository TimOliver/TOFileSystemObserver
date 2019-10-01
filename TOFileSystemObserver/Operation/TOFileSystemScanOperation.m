//
//  TOFileSystemScanOperation.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemScanOperation.h"
#import "TOFileSystemItem.h"
#import "TOFileSystemRealmConfiguration.h"

#import <Realm/Realm.h>

@interface TOFileSystemScanOperation ()

@property (nonatomic, strong) RLMRealmConfiguration *realmConfiguration;
@property (nonatomic, copy) NSString *directoryUUID;
@property (nonatomic, strong) NSURL *directoryURL;

@end

@implementation TOFileSystemScanOperation

- (instancetype)initWithDirectoryItem:(TOFileSystemItem *)directoryItem
                   realmConfiguration:(RLMRealmConfiguration *)realmConfiguration
{
    if (self = [super init]) {
        _directoryUUID = directoryItem.uuid;
        _realmConfiguration = realmConfiguration;
    }

    return self;
}

- (void)main
{
    // Fetch a thread-specific copy of the object we're targetting
    RLMRealm *realm = [RLMRealm realmWithConfiguration:self.realmConfiguration error:nil];
    TOFileSystemItem *item = [TOFileSystemItem objectInRealm:realm forPrimaryKey:self.directoryUUID];

    
}

@end
