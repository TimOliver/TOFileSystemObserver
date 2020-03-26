//
//  ViewController.m
//  TOFileSystemObserverMacExample
//
//  Created by Anatoly Rosencrantz on 26/03/2020.
//  Copyright © 2020 Tim Oliver. All rights reserved.
//

#import "ARViewController.h"
#import "TOFileSystemObserver.h"
#import "TOFileSystemObserver+AppKit.h"
#import "ARImages.h"

@interface ARViewController ()

@property (nonatomic, strong) TOFileSystemObserver *observer;
@property (nonatomic, strong) TOFileSystemItemList *fileItemList;
@property (nonatomic, strong) TOFileSystemNotificationToken *listToken;
@property (nonatomic, strong) TOFileSystemNotificationToken *observerToken;

@property (nonatomic, strong) NSImage *folderIcon;
@property (nonatomic, strong) NSImage *fileIcon;

@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation ARViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.folderIcon = [ARImages documentPickerDefaultFolderForStyle:NO];
    self.fileIcon = [ARImages documentPickerDefaultFileIconWithExtension:@"" tintColor:[NSColor colorForControlTint:[NSColor currentControlTint]] style:NO];

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
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.fileItemList.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    TOFileSystemItem *fileItem = self.fileItemList[row];
    
    if ([tableColumn.identifier isEqualToString: @"NameColumn"]) {
        static NSString *cellIdentifier = @"NameCell";
        NSTableCellView* cell = [tableView makeViewWithIdentifier:cellIdentifier owner:nil];
        
        cell.textField.stringValue = fileItem.name;
        
        if (fileItem.type == TOFileSystemItemTypeDirectory) {
            cell.imageView.image = self.folderIcon;
        }
        else {
            cell.imageView.image = self.fileIcon;
        }
        
        return cell;
    }
    else if ([tableColumn.identifier isEqualToString: @"StatusColumn"]) {
        static NSString *cellIdentifier = @"StatusCell";
        NSTableCellView* cell = [tableView makeViewWithIdentifier:cellIdentifier owner:nil];
        
        if (fileItem.isCopying) {
            cell.textField.stringValue = @"Copying";
        }
        else {
            if (fileItem.type == TOFileSystemItemTypeDirectory) {
                if (fileItem.numberOfSubItems == 1) {
                    cell.textField.stringValue = @"1 item";
                }
                else {
                    cell.textField.stringValue = [NSString stringWithFormat:@"%ld items", (long)fileItem.numberOfSubItems];
                }
            }
            else {
                cell.textField.stringValue = [NSByteCountFormatter stringFromByteCount:fileItem.size
                                                                           countStyle:NSByteCountFormatterCountStyleFile];
            }
        }
        return cell;
    }
    
    return nil;
}


@end
