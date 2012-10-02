//
//  BufferedDownloadViewController.m
//  MUKNetworkingExample
//
//  Created by Marco Muccinelli on 21/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BufferedDownloadViewController.h"

@interface BufferedDownloadViewController ()

@end

@implementation BufferedDownloadViewController
@synthesize imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Buffered Download";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.imageView = nil;
}

#pragma mark - Overrides

- (void)startButtonPressed:(id)sender {
    self.imageView.image = nil;
    [super startButtonPressed:sender];
}

- (MUKURLConnection *)createConnection {
    NSURL *url = [NSURL URLWithString:@"http://4.bp.blogspot.com/-7CkVJATx8UA/To1Ve_U9UgI/AAAAAAAAAUk/uTQTKaFOvpY/s1600/steve-jobs-on-time.png"];
    MUKURLConnection *download = [[MUKURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url]];
    
    return download;
}

- (void)attachHandlersToConnection:(__weak MUKURLConnection *)connection
{
    __weak BufferedDownloadViewController *weakSelf = self;
    
    __block NSInteger chunksCount = 0;
    
    connection.responseHandler = ^(NSURLResponse *response) {
        chunksCount = 0;
    };
    
    connection.progressHandler = ^(NSData *chunk, float quota) {
        weakSelf.progressView.progress = quota;
        NSString *progressString = [[NSString alloc] initWithFormat:@"Received: %lld of %lld", connection.receivedBytesCount, connection.expectedBytesCount];
        weakSelf.progressLabel.text = progressString;
        NSLog(@"%@", progressString);
        chunksCount++;
    };
    
    connection.completionHandler = ^(BOOL success, NSError *error) {
        UIImage *image = [[UIImage alloc] initWithData:[connection bufferedData]];
        weakSelf.imageView.image = image;
        
        NSString *text = (success ? @"Success" : @"Error");
        text = [text stringByAppendingFormat:@" after %i chunks", chunksCount];
        
        if (error) {
            text = [text stringByAppendingFormat:@": %@", [error localizedDescription]];
        }
        weakSelf.progressLabel.text = text;
        
        weakSelf.startButton.enabled = YES;
        weakSelf.cancelButton.enabled = NO;
    };
}

@end
