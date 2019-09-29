//
//  TOFileSystemRealmConfiguration.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "RLMRealmConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface TOFileSystemRealmConfiguration : RLMRealmConfiguration

+ (RLMRealmConfiguration *)fileSystemConfigurationWithFileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
