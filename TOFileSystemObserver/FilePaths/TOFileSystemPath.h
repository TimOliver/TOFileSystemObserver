//
//  TOFileSystemPath.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 29/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A static class to centralize all file path
 manipulation logic.
 */
@interface TOFileSystemPath : NSObject

/** The path to the application sandbox. */
+ (NSURL *)applicationSandboxURL;

/** The path to the application documents directory. */
+ (NSURL *)documentsDirectoryURL;

/** The path to the application caches directory. */
+ (NSURL *)cachesDirectoryURL;

/** The default database file name. */
+ (NSString *)defaultDatabaseFileName;

@end

NS_ASSUME_NONNULL_END
