//
//  TOFileSystemObserver.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemObserver.h"
#import "TOFileSystemPath.h"

@interface TOFileSystemObserver()

@property (nonatomic, assign, readwrite) BOOL isRunning;

@end

@implementation TOFileSystemObserver

- (instancetype)init
{
    if (self = [super init]) {
        [self setUp];
    }

    return self;
}

- (void)setUp
{
    // Set-up default property values
    _isRunning = NO;
    _excludedItems = @[@"Inbox"];
    _targetDirectoryURL = [TOFileSystemPath documentsDirectoryURL];
    _databaseFileName = [TOFileSystemPath defaultDatabaseFileName];
    _databaseDirectoryURL = [TOFileSystemPath cachesDirectoryURL];
}

@end
