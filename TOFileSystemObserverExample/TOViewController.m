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

@end

@implementation TOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"TOFileSystemObserver";

    self.observer = [[TOFileSystemObserver alloc] init];
    [self.observer start];

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    cell.textLabel.text = @"Cell";

    return cell;
}

@end
