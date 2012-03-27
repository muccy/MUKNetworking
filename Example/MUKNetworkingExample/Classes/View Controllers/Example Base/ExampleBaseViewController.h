//
//  ExampleBaseViewController.h
//  MUKNetworkingExample
//
//  Created by Marco Muccinelli on 21/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExampleBaseViewController : UIViewController
/*
 Lazily loaded with -createConnection and -attachHandlersToConnection:
 */
@property (nonatomic, strong) MUKURLConnection *connection;

@property (nonatomic, strong) IBOutlet UIButton *startButton, *cancelButton;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UILabel *progressLabel;

- (IBAction)startButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

/*
 Default: nil
 */
- (MUKURLConnection *)createConnection;

- (void)attachHandlersToConnection:(__unsafe_unretained MUKURLConnection *)connection;
@end
