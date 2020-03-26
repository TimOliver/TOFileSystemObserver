//
//  ARImages.h
//  TOFileSystemObserverExample
//
//  Created by Anatoly Rosencrantz on 26/03/2020.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARImages : NSImage

+ (NSImage *)documentPickerDefaultFolderForStyle:(BOOL)darkMode;

+ (NSImage *)documentPickerDefaultFileIconWithExtension:(NSString *)extension
                                                 tintColor:(NSColor *)tintColor
                                                  style:(BOOL)darkMode;
@end

NS_ASSUME_NONNULL_END

