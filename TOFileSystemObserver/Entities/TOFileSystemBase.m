//
//  TOFileSystemBase.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemBase.h"

@implementation TOFileSystemBase

// Never automatically include this in the default Realm schema
// as it may get exposed in the app's own Realm files.
+ (BOOL)shouldIncludeInDefaultSchema { return NO; }

@end
