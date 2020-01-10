//
//  TOFileSystemNotificationHandler.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TOFileSystemNotificationToken;

/** A protocol denoting that the object can serve notification tokens. */
@protocol TOFileSystemNotifying <NSObject>

@required
/** Removes the notification from the observing object. */
- (void)removeNotificationToken:(TOFileSystemNotificationToken *)token;

@end

@interface TOFileSystemNotificationToken ()

/** The object for which this token was generated from. */
@property (nonatomic, weak, readwrite) id<TOFileSystemNotifying> observingObject;

/** The block that will be triggered each time an event occurs. */
@property (nonatomic, copy, readwrite) void (^notificationBlock)(id observer, id changes);

/** Create a new instance with the observer and the block */
+ (instancetype)tokenWithObservingObject:(id<TOFileSystemNotifying>)observingObject
                                   block:(void (^)(id, id))block;

@end

NS_ASSUME_NONNULL_END
