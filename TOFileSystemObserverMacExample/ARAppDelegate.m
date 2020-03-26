//
//  AppDelegate.m
//  TOFileSystemObserverMacExample
//
//  Created by Anatoly Rosencrantz on 26/03/2020.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import "ARAppDelegate.h"
#import "TOFileSystemPath.h"

@interface ARAppDelegate ()

@end

@implementation ARAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setUpDefaultData];
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
