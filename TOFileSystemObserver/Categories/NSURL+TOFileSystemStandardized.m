//
//  NSURL+TOFileSystemStandardized.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2019/12/29.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "NSURL+TOFileSystemStandardized.h"

@implementation NSURL (TOFileSystemStandardized)

- (NSString *)to_standardizedPath
{
    NSString *filePath = self.path;
    return filePath.stringByStandardizingPath;
}

- (NSURL *)to_standardizedURL
{
    return [NSURL fileURLWithPath:self.to_standardizedPath];
}

@end
