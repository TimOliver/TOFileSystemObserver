//
//  TOFileSystemNotificationHandler.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemNotificationToken.h"

@implementation TOFileSystemNotificationToken

- (void)dealloc
{
    [self invalidate];
}

@end
