//
//  TOFileSystemNotificationHandler.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOFileSystemNotificationToken.h"
#import "TOFileSystemNotificationToken+Private.h"

@implementation TOFileSystemNotificationToken

#pragma mark - Class Creation -

+ (instancetype)tokenWithObservingObject:(id<TOFileSystemNotifying>)observingObject
                                   block:(void (^)(id _Nonnull, id _Nonnull))block
{
    TOFileSystemNotificationToken *token = [[TOFileSystemNotificationToken alloc] init];
    token.observingObject = observingObject;
    token.notificationBlock = block;
    return token;
}

- (void)dealloc
{
    [self invalidate];
}

- (void)invalidate
{
    [self.observingObject removeNotificationToken:self];
}

@end
