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

#import "MUKURLConnectionQueue.h"
#import "MUKURLConnectionOperation_.h"
#import "MUKURLConnectionQueue_Background.h"

NSInteger const MUKURLConnectionQueueDefaultMaxConcurrentConnections = NSOperationQueueDefaultMaxConcurrentOperationCount;

@interface MUKURLConnectionQueue ()
@property (nonatomic, strong) NSOperationQueue *queue_;

- (MUKURLConnectionOperation_ *)newOperationFromConnection_:(MUKURLConnection *)connection;
@end

@implementation MUKURLConnectionQueue
@synthesize connectionWillStartHandler = connectionWillStartHandler_;
@synthesize connectionDidFinishHandler = connectionDidFinishHandler_;
@synthesize queue_ = queue__;

#pragma mark - Methods

- (BOOL)addConnection:(MUKURLConnection *)connection {
    MUKURLConnectionOperation_ *op = [self newOperationFromConnection_:connection];
    
    BOOL inserted;
    @try {
        /*
         If connection should run in background, make operation to run in 
         background too.
         */
        [self beginBackgroundTaskIfNeededInOperation_:op];
        /*
         Add operation
         */
        [self.queue_ addOperation:op];
        inserted = YES;
    }
    @catch (NSException *exception) {
        inserted = NO;
    }
    
    return inserted;
}

- (BOOL)addConnections:(NSArray *)connections {
    NSMutableArray *operations = [[NSMutableArray alloc] initWithCapacity:[connections count]];
    [connections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        MUKURLConnectionOperation_ *op = [self newOperationFromConnection_:obj];
        /*
         If connection should run in background, make operation to run in 
         background too.
         */
        [self beginBackgroundTaskIfNeededInOperation_:op];
        
        [operations addObject:op];
    }];
    
    BOOL inserted;
    @try {
        [self.queue_ addOperations:operations waitUntilFinished:NO];
        inserted = YES;
    }
    @catch (NSException *exception) {
        inserted = NO;
    }
    
    return inserted;
}

- (NSArray *)connections {
    NSMutableArray *connectionOperations = [NSMutableArray array];
    [[self.queue_ operations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[MUKURLConnectionOperation_ class]]) {
            [connectionOperations addObject:obj];
        }
    }];
    
    return connectionOperations;
}

- (void)cancelAllConnections {
    [[self.queue_ operations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        if ([obj isKindOfClass:[MUKURLConnectionOperation_ class]]) {
            [(MUKURLConnectionOperation_ *)obj cancel];
            
            // Operation background task is ended in operation's completion block
        }
    }];
}

#pragma mark - Callbacks

- (void)willStartConnection:(MUKURLConnection *)connection {
    if (self.connectionWillStartHandler) {
        self.connectionWillStartHandler(connection);
    }
}

- (void)didFinishConnection:(MUKURLConnection *)connection cancelled:(BOOL)cancelled
{
    if (self.connectionDidFinishHandler) {
        self.connectionDidFinishHandler(connection, cancelled);
    }
}

#pragma mark - Accessors

- (NSInteger)maximumConcurrentConnections {
    return [self.queue_ maxConcurrentOperationCount];
}

- (void)setMaximumConcurrentConnections:(NSInteger)maximumConcurrentConnections
{
    [self.queue_ setMaxConcurrentOperationCount:maximumConcurrentConnections];
}

- (NSString *)name {
    return [self.queue_ name];
}

- (void)setName:(NSString *)name {
    [self.queue_ setName:name];
}

- (BOOL)isSuspended {
    return [self.queue_ isSuspended];
}

- (void)setSuspended:(BOOL)suspended {
    [self.queue_ setSuspended:suspended];
}

#pragma mark - Private: Accessors

- (NSOperationQueue *)queue_ {
    if (queue__ == nil) {
        self.queue_ = [[NSOperationQueue alloc] init];
    }
    return queue__;
}

#pragma mark - Private

- (MUKURLConnectionOperation_ *)newOperationFromConnection_:(MUKURLConnection *)connection
{
    MUKURLConnectionOperation_ *op = [[MUKURLConnectionOperation_ alloc] initWithConnection:connection];
    MUKURLConnectionOperation_ *strongOp = op;
    
    /*
     Keeping strong pointers to operation and to queue make sure every handler
     is called once and queue is kept alive.
     When last operation is dismissed, queue will be dealloc'd
     */
    op.connectionWillStartHandler = ^{
        [self willStartConnection:strongOp.connection];
        
        // Break cycle
        strongOp.connectionWillStartHandler = nil;
    };
    
    op.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self didFinishConnection:strongOp.connection cancelled:[strongOp isCancelled]];
            [self endBackgroundTaskIfNeededInOperation_:strongOp];
            
            // Break cycle
            strongOp.completionBlock = nil;
        });
    };
    
    return op;
}

#pragma mark - Private: Background

- (void)beginBackgroundTaskIfNeededInOperation_:(MUKURLConnectionOperation_ *)op
{
    if (op.connection.runsInBackground) {
        if (op.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            op.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
            {
                [self endBackgroundTaskIfNeededInOperation_:op];
            }];
        }
    }
}

- (void)endBackgroundTaskIfNeededInOperation_:(MUKURLConnectionOperation_ *)op {
    if (op.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        UIBackgroundTaskIdentifier tid = op.backgroundTaskIdentifier;
        op.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        [[UIApplication sharedApplication] endBackgroundTask:tid];
    }
}

@end
