//
//  TOFileSystemNotificationHandler.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TOFileSystemObserver;
@class TOFileSystemChanges;

NS_ASSUME_NONNULL_BEGIN

/**
 An opaque token object used to track registered notification blocks.

 It is your responsibility to maintain a strong reference to this
 object for the duration that you wish to receive events. It will
 remove itself from the observing object when deallocated.
 */
@interface TOFileSystemNotificationToken : NSObject

/**
 Stops all notifications being made to the block, and removes it
 from the file system observer.
 */
- (void)invalidate;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
