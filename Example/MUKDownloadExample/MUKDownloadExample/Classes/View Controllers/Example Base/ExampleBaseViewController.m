//
//  ExampleBaseViewController.m
//  MUKDownloadExample
//
//  Created by Marco Muccinelli on 21/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExampleBaseViewController.h"

@interface ExampleBaseViewController ()

@end

@implementation ExampleBaseViewController
@synthesize connection = connection_;
@synthesize startButton, cancelButton;
@synthesize progressView;
@synthesize progressLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [connection_ cancel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.startButton.enabled = YES;
    self.cancelButton.enabled = NO;
    self.progressView.progress = 0.0;
    self.progressLabel.text = @"Idle";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.startButton = nil;
    self.cancelButton = nil;
    self.progressLabel = nil;
    self.progressView = nil;
}

#pragma mark - Accessors

- (MUKURLConnection *)connection {
    if (connection_ == nil) {
        self.connection = [self createConnection];
        
        __unsafe_unretained MUKURLConnection *weakConnection = connection_;
        [self attachHandlersToConnection:weakConnection];
    }
    return connection_;
}

#pragma mark - Methods

- (MUKURLConnection *)createConnection {
    return nil;
}

- (void)attachHandlersToConnection:(MUKURLConnection *)connection {
    //
}

#pragma mark - IBActions

- (void)startButtonPressed:(id)sender {
    [self.connection start];
    
    self.progressLabel.text = @"Starting...";
    self.progressView.progress = 0.0;
    self.startButton.enabled = NO;
    self.cancelButton.enabled = YES;
}

- (void)cancelButtonPressed:(id)sender {
    [self.connection cancel];
    
    self.progressLabel.text = @"Canceled";
    self.progressView.progress = 0.0;
    self.startButton.enabled = YES;
    self.cancelButton.enabled = NO;
}

@end
