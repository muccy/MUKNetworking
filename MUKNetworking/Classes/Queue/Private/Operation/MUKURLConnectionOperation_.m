// Copyright (c) 2012, Marco Muccinelli
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
// * Neither the name of the <organization> nor the
// names of its contributors may be used to endorse or promote products
// derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MUKURLConnectionOperation_.h"
#import "MUKURLConnection_Queue.h"

@interface MUKURLConnectionOperation_ ()
@property (nonatomic) BOOL connectionFinished_;
@end

@implementation MUKURLConnectionOperation_
@synthesize connection = connection_;
@synthesize connectionWillStartHandler = connectionWillStartHandler_;
@synthesize connectionDidFinishHandler = connectionDidFinishHandler_;
@synthesize connectionFinished_ = connectionFinished__;

- (void)dealloc {
    self.connection.operationCompletionHandler_ = nil;
    self.connectionWillStartHandler = nil;
    self.connectionDidFinishHandler = nil;
}

- (void)main {  
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    __unsafe_unretained MUKURLConnectionOperation_ *weakSelf = self;
    
    self.connection.operationCompletionHandler_ = ^(BOOL success, NSError *error) {
        // Called in main queue
        // Set connectionFinished_ in operation's queue
        dispatch_async(currentQueue, ^{
            weakSelf.connectionFinished_ = YES;
            
            if (self.connectionDidFinishHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.connectionDidFinishHandler(success, error);
                });
            }
        });
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.connectionWillStartHandler) {
            self.connectionWillStartHandler();
        }
        
        // Schedule connection on main run loop
        [self.connection start];
    });
}

- (void)cancel {
    [super cancel];
    
    self.connection.operationCompletionHandler_ = nil;
    self.connectionWillStartHandler = nil;
    self.connectionDidFinishHandler = nil;
    
    // Cancel connection
    [self.connection cancel];
    
    self.connectionFinished_ = YES;
}

- (BOOL)isFinished {
    return self.connectionFinished_;
}

#pragma mark - Accessors

- (void)setConnectionFinished_:(BOOL)connectionFinished_ {
    if (connectionFinished_ != connectionFinished__) {
        [self willChangeValueForKey:@"isFinished"];
        connectionFinished__ = connectionFinished_;
        [self didChangeValueForKey:@"isFinished"];
    }
}

@end
