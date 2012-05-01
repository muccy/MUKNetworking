//
//  BackgroundBufferedDownloadViewController.m
//  MUKNetworkingExample
//
//  Created by Marco Muccinelli on 01/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BackgroundBufferedDownloadViewController.h"

@interface BackgroundBufferedDownloadViewController ()

@end

@implementation BackgroundBufferedDownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Background Download";
    }
    return self;
}

- (MUKURLConnection *)createConnection {
    MUKURLConnection *download = [super createConnection];
    download.runsInBackground = YES;
    return download;
}

@end
