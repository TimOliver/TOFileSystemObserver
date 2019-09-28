//
//  TOFileSystemItem.h
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

// The different types of items stored in the file system
NS_ENUM(NSInteger, TOFileSystemItemType) {
    TOFileSystemItemTypeFile, // A standard file
    TOFileSystemItemTypeDirectory // A folder
};

NS_ASSUME_NONNULL_BEGIN

@interface TOFileSystemItem : RLMObject

@property (nonatomic, assign) TOFileSystemItemType type;

@end

NS_ASSUME_NONNULL_END
