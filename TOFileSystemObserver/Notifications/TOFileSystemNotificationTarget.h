//
//  TOFileSystemNotificationTarget.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An internal object that tracks registered
 target objects and the selector they have supplied.
 */
@interface TOFileSystemNotificationTarget : NSObject

/** The target object that the selector will be sent to. */
@property (nonatomic, weak) id target;

/** The selector belonging to the target object that will be called. */
@property (nonatomic, assign) SEL selector;

@end

NS_ASSUME_NONNULL_END
