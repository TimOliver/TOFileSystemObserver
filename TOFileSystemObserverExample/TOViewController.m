//
//  ViewController.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOViewController.h"
#import "TOFileSystemObserver.h"

@interface TOViewController ()

@property (nonatomic, strong) TOFileSystemObserver *observer;
@property (nonatomic, strong) TOFileSystemItemList *fileItemList;
@property (nonatomic, strong) TOFileSystemNotificationToken *listToken;

@end

@implementation TOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"TOFileSystemObserver";

    // Create a file system observer and start it
    self.observer = [[TOFileSystemObserver alloc] init];
    [self.observer start];

    // Create a live list of the base folder for this controller
    self.fileItemList = [self.observer itemListForDirectoryAtURL:nil];
    
    __weak typeof(self) weakSelf = self;
    self.listToken = [self.fileItemList addNotificationBlock:^(TOFileSystemItemList *itemList,
                                                               TOFileSystemItemListChanges *changes)
    {
        UITableView *tableView = weakSelf.tableView;
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[changes indexPathsForDeletionsInSection:0]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView insertRowsAtIndexPaths:[changes indexPathsForInsertionsInSection:0]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView reloadRowsAtIndexPaths:[changes indexPathsForModificationsInSection:0]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        
        NSDictionary *movements = changes.movements;
        for (NSNumber *sourceNumber in movements) {
            NSIndexPath *sourceIndex = [NSIndexPath indexPathForRow:sourceNumber.intValue inSection:0];
            NSIndexPath *destIndex = [NSIndexPath indexPathForRow:[movements[sourceNumber] intValue] inSection:0];
            [tableView moveRowAtIndexPath:sourceIndex toIndexPath:destIndex];
        }
        
        [tableView endUpdates];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fileItemList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    TOFileSystemItem *fileItem = self.fileItemList[indexPath.row];
    cell.textLabel.text = fileItem.name;

    return cell;
}

@end
