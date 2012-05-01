//
//  QueueViewController.m
//  MUKNetworkingExample
//
//  Created by Marco Muccinelli on 01/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QueueViewController.h"

@interface IndexedConnection_ : MUKURLConnection
@property (nonatomic) NSInteger index;
@end

@implementation IndexedConnection_
@synthesize index;
@end

#pragma mark - 
#pragma mark - 

@implementation QueueViewController
@synthesize queue = queue_;
@synthesize startButton, cancelButton;
@synthesize imageViews;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Queue";
    }
    return self;
}

- (void)dealloc {
    [self.queue cancelAllConnections];
    self.queue.connectionWillStartHandler = nil;
    self.queue.connectionDidFinishHandler = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)startButtonPressed:(id)sender {
    NSArray *URLs = [[NSArray alloc] initWithObjects:
                     [NSURL URLWithString:@"http://farm4.staticflickr.com/3159/3019874112_769b607d2f.jpg"],
                     [NSURL URLWithString:@"http://farm8.staticflickr.com/7026/6793115731_f22b97df92.jpg"],
                     [NSURL URLWithString:@"http://farm1.staticflickr.com/9/77539733_e64a5917a1.jpg"],
                     [NSURL URLWithString:@"http://farm3.staticflickr.com/2361/2351000967_245c4d028d.jpg"],
                     nil];
    
    self.queue = [[MUKURLConnectionQueue alloc] init];
    self.queue.maximumConcurrentConnections = 2;
    
    self.queue.connectionWillStartHandler = ^(MUKURLConnection *conn) {
        NSLog(@"Will start connection %i", [(IndexedConnection_ *)conn index]);
    };
    
    self.queue.connectionDidFinishHandler = ^(MUKURLConnection *conn, BOOL cancelled) 
    {
        NSLog(@"Did finish connection %i (cancelled: %i)", [(IndexedConnection_ *)conn index], cancelled);
    };
    
    [URLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSURL *URL = obj;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        IndexedConnection_ *connection = [[IndexedConnection_ alloc] initWithRequest:request];
        connection.runsInBackground = YES;
        connection.index = idx;
        
        __unsafe_unretained MUKURLConnection *weakConnection = connection;
        
        connection.completionHandler = ^(BOOL success, NSError *error) {
            NSData *data = [weakConnection bufferedData];
            UIImage *image = [[UIImage alloc] initWithData:data];
            NSLog(@"Image %i received", idx);
            [[self.imageViews objectAtIndex:idx] setImage:image];
        };
        
        [self.queue addConnection:connection];
    }];
}

- (void)cancelButtonPressed:(id)sender {
    [self.imageViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setImage:nil];
    }];
    
    [self.queue cancelAllConnections];
    self.queue.connectionWillStartHandler = nil;
    self.queue.connectionDidFinishHandler = nil;
    self.queue = nil;
}

@end
