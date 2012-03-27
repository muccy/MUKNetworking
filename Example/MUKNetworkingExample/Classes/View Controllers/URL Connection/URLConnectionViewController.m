//
//  URLConnectionViewController.m
//  MUKNetworkingExample
//
//  Created by Marco Muccinelli on 21/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "URLConnectionViewController.h"

@interface URLConnectionViewController ()

@end

@implementation URLConnectionViewController
@synthesize textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Unbuffered Connection";
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
    self.textView = nil;
}

#pragma mark - Overrides

- (void)startButtonPressed:(id)sender {
    self.textView.text = nil;
    [super startButtonPressed:sender];
}

- (MUKURLConnection *)createConnection {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    connection.usesBuffer = NO;
    return connection;
}

- (void)attachHandlersToConnection:(__unsafe_unretained MUKURLConnection *)connection 
{
    __unsafe_unretained URLConnectionViewController *weakSelf = self;
    
    __block NSInteger chunkIndex = 0;
    
    connection.responseHandler = ^(NSURLResponse *response) {
        chunkIndex = 0;
    };
    
    connection.progressHandler = ^(NSData *chunk, float quota) {
        weakSelf.progressView.progress = quota;
        weakSelf.progressLabel.text = [NSString stringWithFormat:@"Received: %lld of %lld", connection.receivedBytesCount, connection.expectedBytesCount];
        
        NSString *text = weakSelf.textView.text;
        text = [text stringByAppendingFormat:@"### Chunk %i (%i) ###\n", chunkIndex, [chunk length]];
        text = [text stringByAppendingFormat:@"%@\n", chunk];
        
        NSString *dataString = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        text = [text stringByAppendingFormat:@"-------\n%@\n\n\n", dataString];
        
        weakSelf.textView.text = text;
        
        chunkIndex++;
    };
    
    connection.completionHandler = ^(BOOL success, NSError *error) {
        NSString *text = (success ? @"Success" : @"Error");
        
        text = [text stringByAppendingFormat:@" after %i chunks", chunkIndex];
        
        if (error) {
            text = [text stringByAppendingFormat:@": %@", [error localizedDescription]];
        }
        
        weakSelf.progressLabel.text = text;
        
        weakSelf.startButton.enabled = YES;
        weakSelf.cancelButton.enabled = NO;
    };
}

@end
