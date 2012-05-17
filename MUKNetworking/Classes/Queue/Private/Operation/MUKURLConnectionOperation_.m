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

// Don't produce KVO
@property (atomic) BOOL isExecuting_, isFinished_, isCancelled_;

- (void)setupHandlers_;
- (void)finish_;
@end

@implementation MUKURLConnectionOperation_
@synthesize connection = connection_;
@synthesize connectionWillStartHandler = connectionWillStartHandler_;
@synthesize backgroundTaskIdentifier = backgroundTaskIdentifier_;

@synthesize isExecuting_ = isExecuting__, isFinished_ = isFinished__;
@synthesize isCancelled_ = isCancelled__;

- (id)init {
    self = [self initWithConnection:nil];
    return self;
}

- (id)initWithConnection:(MUKURLConnection *)connection {
    self = [super init];
    if (self) {
#if DEBUG_LOG
        NSLog(@"Connection operation init (%@)", connection);
#endif
        self.connection = connection;
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        
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

- (void)start {
    // Ensure start in called on main thread
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:self waitUntilDone:NO];
        return;
    }
        
    // Always check for cancellation
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        self.isFinished_ = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // Operation is not cancelled
    [self willChangeValueForKey:@"isExecuting"];
    self.isExecuting_ = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    // Start connection
    if (self.connectionWillStartHandler) {
        self.connectionWillStartHandler();
    }
    
    // Don't start connection if user cancelled it
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        self.isFinished_ = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // Start connection
    [self.connection start];
}

- (void)cancel {    
    // Cancel connection
    // Set operationCancelHandler_ to nil to prevent recursion
    self.connection.operationCancelHandler_ = nil;
    [self.connection cancel];
    
    [self willChangeValueForKey:@"isCancelled"];
    self.isCancelled_ = YES;
    [self didChangeValueForKey:@"isCancelled"];
}

- (BOOL)isFinished {
    return self.isFinished_;
}

- (BOOL)isCancelled {
    return self.isCancelled_;
}

- (BOOL)isExecuting {
    return self.isExecuting_;
}

#pragma mark - Private

- (void)setupHandlers_ {
    __unsafe_unretained MUKURLConnectionOperation_ *weakSelf = self;
    
    self.connection.operationCancelHandler_ = ^{
        // Called in main queue
        [weakSelf cancel];
    };
    
    self.connection.operationCompletionHandler_ = ^(BOOL success, NSError *error) 
    {
        // Called in main queue
        [weakSelf finish_];
    };
}

- (void)finish_ {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    self.isExecuting_ = NO;
    self.isFinished_ = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
