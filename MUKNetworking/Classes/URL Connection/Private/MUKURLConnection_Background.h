//
//  MUKURLConnection_Background.h
//  MUKNetworking
//
//  Created by Marco Muccinelli on 01/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKURLConnection.h"
#import <UIKit/UIKit.h>

@interface MUKURLConnection ()
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier_;

- (void)beginBackgroundTaskIfNeeded_;
- (void)endBackgroundTaskIfNeeded_;

@end
