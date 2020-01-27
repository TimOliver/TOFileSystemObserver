//
//  TOImages.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2020/01/27.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOImages : UIImage

+ (UIImage *)downloadIcon;

+ (UIImage *)documentPickerDefaultFolderForStyle:(BOOL)darkMode;

+ (UIImage *)documentPickerFolderIconWithSize:(CGSize)size
                                 backgroundColor:(UIColor *)backgroundColor
                           foregroundBottomColor:(UIColor *)foregroundBottomColor
                              foregroundTopColor:(UIColor *)foregroundTopColor;

+ (UIImage *)documentPickerDefaultFileIconWithExtension:(NSString *)extension
                                                 tintColor:(UIColor *)tintColor
                                                  style:(BOOL)darkMode;

+ (UIImage *)documentPickerIconWithSize:(CGSize)size
                                     outlineColor:(UIColor *)outlineColor
                                  backgroundColor:(UIColor *)backgroundColor
                                      cornerColor:(UIColor *)cornerColor
                                 formatNameString:(NSString *)formatNameString
                                   formatNameFont:(UIFont *)formatNameFont
                                  formatNameColor:(UIColor *)formatNameColor;

@end

NS_ASSUME_NONNULL_END
