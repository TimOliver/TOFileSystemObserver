//
//  NSURL+TOFileSystemStandardized.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 2019/12/29.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "NSURL+TOFileSystemStandardized.h"

@implementation NSURL (TOFileSystemStandardized)

- (NSURL *)to_standardizedURL
{
    NSString *filePath = self.path;
    filePath = filePath.stringByStandardizingPath;
    return [NSURL fileURLWithPath:filePath];
}

@end
