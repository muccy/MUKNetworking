//
//  MUKURLConnectionQueue_Background.h
//  MUKNetworking
//
//  Created by Marco Muccinelli on 01/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MUKURLConnectionQueue.h"

@class MUKURLConnectionOperation_;
@interface MUKURLConnectionQueue ()

- (void)beginBackgroundTaskIfNeededInOperation_:(MUKURLConnectionOperation_ *)op;
- (void)endBackgroundTaskIfNeededInOperation_:(MUKURLConnectionOperation_ *)op;

@end
