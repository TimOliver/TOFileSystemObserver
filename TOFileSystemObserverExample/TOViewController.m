//
//  ViewController.m
//  TOFileSystemObserverExample
//
//  Created by Tim Oliver on 28/9/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "TOViewController.h"

#import "TOImages.h"
#import "TOFileSystemObserver.h"
#import "TOFileSystemObserver+UIKit.h"

@interface TOViewController ()

@property (nonatomic, strong) TOFileSystemObserver *observer;
@property (nonatomic, strong) TOFileSystemItemList *fileItemList;
@property (nonatomic, strong) TOFileSystemNotificationToken *listToken;
@property (nonatomic, strong) TOFileSystemNotificationToken *observerToken;

@property (nonatomic, strong) UIImage *folderIcon;
@property (nonatomic, strong) UIImage *fileIcon;

@end

@implementation TOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"TOFileSystemObserver";
    self.tableView.rowHeight = 74;
    
    self.folderIcon = [TOImages documentPickerDefaultFolderForStyle:NO];
    self.fileIcon = [TOImages documentPickerDefaultFileIconWithExtension:@"" tintColor:self.view.tintColor style:NO];
    
    // Create a file system observer and start it
    self.observer = [[TOFileSystemObserver alloc] init];
    [self.observer start];

    // Create a live list of the base folder for this controller
    self.fileItemList = [self.observer itemListForDirectoryAtURL:nil];
    
    __weak typeof(self) weakSelf = self;
    self.listToken = [self.fileItemList addNotificationBlock:^(TOFileSystemItemList *itemList,
                                                               TOFileSystemItemListChanges *changes)
    {
        TOFileSystemItemListUpdateTableView(weakSelf.tableView, changes, 0);
    }];
    
    self.observerToken = [self.observer addNotificationBlock:^(TOFileSystemObserver *observer,
                                                               TOFileSystemObserverNotificationType type,
                                                               TOFileSystemChanges *changes)
    {
        if (type == TOFileSystemObserverNotificationTypeWillBeginFullScan) {
            NSLog(@"Scan Will Start!");
            return;
        }
        
        if (type == TOFileSystemObserverNotificationTypeDidCompleteFullScan) {
            NSLog(@"Scan Complete!");
            return;
        }
        
        NSLog(@"%@", changes);
    }];
    
    // Add test button for flipping direction
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Asc"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(leftButtonTapped:)];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    // Add test button for rotating list order
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Name"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(rightButtonTapped:)];
    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)leftButtonTapped:(id)sender
{
    BOOL descending = !self.fileItemList.isDescending;
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    item.title = descending ? @"Desc" : @"Asc";
    self.fileItemList.isDescending = descending;
}

- (void)rightButtonTapped:(id)sender
{
    TOFileSystemItemListOrder order = self.fileItemList.listOrder + 1;
    if (order > TOFileSystemItemListOrderSize) { order = 0; }
    
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    switch (order) {
        case TOFileSystemItemListOrderSize:
            item.title = @"Size";
            break;
        case TOFileSystemItemListOrderDate:
            item.title = @"Date";
            break;
        default:
            item.title = @"Name";
            break;
    }
    
    self.fileItemList.listOrder = order;
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    TOFileSystemItem *fileItem = self.fileItemList[indexPath.row];
    cell.textLabel.text = fileItem.name;
    
    if (fileItem.isCopying) {
        cell.detailTextLabel.text = @"Copying";
    }
    else {
        if (fileItem.type == TOFileSystemItemTypeDirectory) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (fileItem.numberOfSubItems == 1) {
                cell.detailTextLabel.text = @"1 item";
            }
            else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld items", (long)fileItem.numberOfSubItems];
            }
            cell.imageView.image = self.folderIcon;
            
            UIEdgeInsets insets = cell.layoutMargins;
            insets.left = 16;
            cell.layoutMargins = insets;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.detailTextLabel.text = @"File";
            cell.imageView.image = self.fileIcon;
            
            UIEdgeInsets insets = cell.layoutMargins;
            insets.left = 27;
            cell.layoutMargins = insets;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
