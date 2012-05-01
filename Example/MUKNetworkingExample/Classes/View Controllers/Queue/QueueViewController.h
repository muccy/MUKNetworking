//
//  QueueViewController.h
//  MUKNetworkingExample
//
//  Created by Marco Muccinelli on 01/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QueueViewController : UIViewController
@property (nonatomic, strong) MUKURLConnectionQueue *queue;

@property (nonatomic, strong) IBOutlet UIButton *startButton, *cancelButton;
@property (nonatomic, strong) IBOutletCollection(UIImageView) NSArray *imageViews;

- (IBAction)startButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

@end
