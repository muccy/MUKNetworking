//
//  RootTableViewControllerViewController.m
//  MUKNetworkingExample
//
//  Created by Marco Muccinelli on 21/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootTableViewController.h"
#import "URLConnectionViewController.h"
#import "BufferedDownloadViewController.h"
#import "BackgroundBufferedDownloadViewController.h"

@interface RootTableViewControllerRowData_ : NSObject
@property (nonatomic, strong) NSString *title, *subtitle;
@property (nonatomic, copy) void (^selectionHandler)(void);

+ (id)rowDataWithTitle:(NSString *)title subtitle:(NSString *)subtitle selectionHandler:(void (^)(void))selectionHandler;
@end

@implementation RootTableViewControllerRowData_
@synthesize title = title_, subtitle = subtitle_;
@synthesize selectionHandler = selectionHandler_;

+ (id)rowDataWithTitle:(NSString *)title subtitle:(NSString *)subtitle selectionHandler:(void (^)(void))selectionHandler
{
    RootTableViewControllerRowData_ *rowData = [[RootTableViewControllerRowData_ alloc] init];
    
    rowData.title = title;
    rowData.subtitle = subtitle;
    rowData.selectionHandler = selectionHandler;
    
    return rowData;
}

@end

#pragma mark - 
#pragma mark - 


@interface RootTableViewController ()
@property (nonatomic, strong) NSArray *rowsData_;
@end

@implementation RootTableViewController
@synthesize rowsData_;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"MUKNetworking Examples";
    }
    return self;
}

#pragma mark - Accessors

- (NSArray *)rowsData_ {
    if (rowsData_ == nil) {
        __unsafe_unretained RootTableViewController *weakSelf = self;
        
        RootTableViewControllerRowData_ *URLConnectionRow = [RootTableViewControllerRowData_ rowDataWithTitle:@"URL Connection" subtitle:@"usesBuffer = NO" selectionHandler:^{
            URLConnectionViewController *viewController = [[URLConnectionViewController alloc] initWithNibName:nil bundle:nil];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        }];
        
        RootTableViewControllerRowData_ *bufferedDownloadRow = [RootTableViewControllerRowData_ rowDataWithTitle:@"Buffered Download" subtitle:@"usesBuffer = YES" selectionHandler:^{
            BufferedDownloadViewController *viewController = [[BufferedDownloadViewController alloc] initWithNibName:nil bundle:nil];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        }];
        
        RootTableViewControllerRowData_ *backgroundDownloadRow = [RootTableViewControllerRowData_ rowDataWithTitle:@"Background Download" subtitle:@"runsInBackground = YES" selectionHandler:^{
            BackgroundBufferedDownloadViewController *viewController = [[BackgroundBufferedDownloadViewController alloc] initWithNibName:@"BufferedDownloadViewController" bundle:nil];
            [weakSelf.navigationController pushViewController:viewController animated:YES];
        }];
        
        rowsData_ = [[NSArray alloc] initWithObjects:URLConnectionRow, bufferedDownloadRow, backgroundDownloadRow, nil];
    }
    
    return rowsData_;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rowsData_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    RootTableViewControllerRowData_ *rowData = [self.rowsData_ objectAtIndex:indexPath.row];
    
    cell.textLabel.text = rowData.title;
    cell.detailTextLabel.text = rowData.subtitle;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RootTableViewControllerRowData_ *rowData = [self.rowsData_ objectAtIndex:indexPath.row];
    
    if (rowData.selectionHandler) {
        rowData.selectionHandler();
    }
}

@end
