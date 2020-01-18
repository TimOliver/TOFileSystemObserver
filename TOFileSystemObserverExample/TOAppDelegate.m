//
//  AppDelegate.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOAppDelegate.h"
#import "TOViewController.h"
#import "TOFileSystemPath.h"

@implementation TOAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];

    [self setUpDefaultData];
    
    TOViewController *viewController = [[TOViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)setUpDefaultData
{
    NSURL *documentsDirectory = [TOFileSystemPath documentsDirectoryURL];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSInteger numberOfItems = [fileManager contentsOfDirectoryAtURL:documentsDirectory
                                         includingPropertiesForKeys:nil
                                                            options:0
                                                              error:nil].count;
    if (numberOfItems > 1) { return; }
    
    // Create 5 folders
    for (NSInteger i = 0; i < 5; i++) {
        NSString *folderName = [NSString stringWithFormat:@"Folder %d", (int)i+1];
        NSURL *folderURL = [documentsDirectory URLByAppendingPathComponent:folderName];
        [fileManager createDirectoryAtURL:folderURL withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // Create 5 arbitrary files
    NSArray *sizes = @[@(5), @(12), @(33), @(15), @(20)];
    for (NSInteger i = 0; i < sizes.count; i++) {
        NSString *fileName = [NSString stringWithFormat:@"File-%d.dat", (int)i+1];
        NSURL *fileURL = [documentsDirectory URLByAppendingPathComponent:fileName];
        FILE *file = fopen([fileURL.path cStringUsingEncoding:NSUTF8StringEncoding], "wb");
        
        NSInteger byteCount = [sizes[i] intValue] * 1000000;
        for (NSInteger j = 0; j < byteCount; j++) {
            fwrite("0", 1, 1, file);
        }
        fclose(file);
    }
}

@end
