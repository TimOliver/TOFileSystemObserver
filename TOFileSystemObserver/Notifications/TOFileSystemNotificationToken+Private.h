//
//  TOFileSystemNotificationToken+Private.h
//
//  Copyright 2019-2020 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
@property (nonatomic, copy, readwrite) id notificationBlock;

/** Create a new instance with the observer and the block */
+ (instancetype)tokenWithObservingObject:(id<TOFileSystemNotifying>)observingObject
                                   block:(id)block;

@end

NS_ASSUME_NONNULL_END
