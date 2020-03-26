//
//  ARImages.m
//  TOFileSystemObserverMacExample
//
//  Created by Anatoly Rosencrantz on 26/03/2020.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARImages.h"

@implementation ARImages
+ (NSURL *)documentsDirectoryURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
}

+ (NSImage *)documentPickerDefaultFolderForStyle:(BOOL)darkMode
{
    NSURL* url = [[self documentsDirectoryURL] URLByAppendingPathComponent:@".tmp"];
    [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:false attributes:nil error:nil];
    NSImage *icon = [[url resourceValuesForKeys:@[NSURLEffectiveIconKey] error:nil] objectForKey:NSURLEffectiveIconKey];
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    return icon;
}

+ (NSImage *)documentPickerDefaultFileIconWithExtension:(NSString *)extension
                                                 tintColor:(NSColor *)tintColor
                                                     style:(BOOL)darkMode
{
    NSURL* url = [[self documentsDirectoryURL] URLByAppendingPathComponent:@".tmp"];
    NSData* data = [[NSData alloc] init];
    [[NSFileManager defaultManager]  createFileAtPath:url.path contents:data attributes:nil];
    NSImage *icon = [[url resourceValuesForKeys:@[NSURLEffectiveIconKey] error:nil] objectForKey:NSURLEffectiveIconKey];
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    return icon;
}

@end
