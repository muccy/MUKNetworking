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

#define DEBUG_LOG      0

@interface MUKURLConnectionOperation_ ()
@property (nonatomic, strong, readwrite) MUKURLConnection *connection;
@property (nonatomic) BOOL connectionFinished_, connectionCancelled_, mainCalled_;

// Pay attention that currentQueue_ could be main queue before -main
// is called (so don't use dispatch_sync)
@property (nonatomic) dispatch_queue_t currentQueue_;

- (void)setupHandlers_;
@end

@implementation MUKURLConnectionOperation_
@synthesize connection = connection_;
@synthesize connectionWillStartHandler = connectionWillStartHandler_;

@synthesize connectionFinished_ = connectionFinished__, connectionCancelled_ = connectionCancelled__, mainCalled_ = mainCalled__;
@synthesize currentQueue_ = currentQueue__;

- (id)initWithConnection:(MUKURLConnection *)connection {
    self = [super init];
    if (self) {
#if DEBUG_LOG
        NSLog(@"Connection operation init (%@)", connection);
#endif
        self.connection = connection;
        self.currentQueue_ = dispatch_get_current_queue();
        [self setupHandlers_];
    }
    return self;
}

- (void)dealloc {
#if DEBUG_LOG
    NSLog(@"Connection operation dealloc (%@)", self.connection);
#endif
    self.connection.operationCancelHandler_ = nil;
    self.connection.operationCompletionHandler_ = nil;
    
    self.connectionWillStartHandler = nil;
    self.completionBlock = nil;
}

#pragma mark - Overrides

- (void)main {  
#if DEBUG_LOG
    NSLog(@"Connection operation main (%@)", self.connection);
#endif
    self.mainCalled_ = YES;
    self.currentQueue_ = dispatch_get_current_queue();
    
    if (self.connectionCancelled_) {
#if DEBUG_LOG
        NSLog(@"Connection operation cancelled in main (%@)", self.connection);
#endif
        [self cancel];
        return;
    }
 
    if (![self isCancelled]) {
        // Start connection
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.connectionWillStartHandler) {
                self.connectionWillStartHandler();
            }
            
            // Schedule connection on main run loop
#if DEBUG_LOG
            NSLog(@"Connection operation started (%@)", self.connection);
#endif
            [self.connection start];
        });
    }
}

- (void)cancel {    
    // Cancel connection
    [self.connection cancel];
    
    /*
     Mark operation as finished (without KVO because signal to queue
     arrives from [super cancel])
     */
    connectionFinished__ = YES;
    
    [super cancel];
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
        
#if DEBUG_LOG
        NSLog(@"Connection operation finished flag changed to %i (%@)", connectionFinished_, self.connection);
#endif
    }
}

#pragma mark - Private

- (void)setupHandlers_ {
    __unsafe_unretained MUKURLConnectionOperation_ *weakSelf = self;
    
    self.connection.operationCancelHandler_ = ^{
        // Called in main queue
        MUKURLConnectionOperation_ *strongSelf = weakSelf;
        
        // Cancel operation in current queue
        dispatch_async(strongSelf.currentQueue_, ^{
            strongSelf.connectionCancelled_ = YES;
            
            if (strongSelf.mainCalled_) {
                [strongSelf cancel];
            }
        });
    };
    
    self.connection.operationCompletionHandler_ = ^(BOOL success, NSError *error) {
        // Called in main queue
        MUKURLConnectionOperation_ *strongSelf = weakSelf;
        
        // Set connectionFinished_ in current queue
        dispatch_async(strongSelf.currentQueue_, ^{
            strongSelf.connectionFinished_ = YES;
        });
    };
}

@end
