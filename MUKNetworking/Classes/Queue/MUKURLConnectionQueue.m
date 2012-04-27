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

NSInteger const MUKURLConnectionQueueDefaultMaxConcurrentConnections = NSOperationQueueDefaultMaxConcurrentOperationCount;

@interface MUKURLConnectionQueue ()
@property (nonatomic, strong) NSOperationQueue *queue_;

- (MUKURLConnectionOperation_ *)newOperationFromConnection_:(MUKURLConnection *)connection;
@end

@implementation MUKURLConnectionQueue
@synthesize connectionWillStartHandler = connectionWillStartHandler_;
@synthesize connectionDidFinishHandler = connectionDidFinishHandler_;
@synthesize queue_ = queue__;

- (void)dealloc {
    [queue__ cancelAllOperations];
}

#pragma mark - Methods

- (void)addConnection:(MUKURLConnection *)connection {
    MUKURLConnectionOperation_ *op = [self newOperationFromConnection_:connection];
    [self.queue_ addOperation:op];
}

- (void)addConnections:(NSArray *)connections {
    NSMutableArray *operations = [[NSMutableArray alloc] initWithCapacity:[connections count]];
    [connections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        MUKURLConnectionOperation_ *op = [self newOperationFromConnection_:obj];
        [operations addObject:op];
    }];
    
    [self.queue_ addOperations:operations waitUntilFinished:NO];
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
    MUKURLConnectionOperation_ *op = [[MUKURLConnectionOperation_ alloc] init];
    __unsafe_unretained MUKURLConnectionOperation_ *weakOp = op;
    __unsafe_unretained MUKURLConnectionQueue *weakSelf = self;
    
    op.connection = connection;
    
    op.connectionWillStartHandler = ^{
        if (weakSelf.connectionWillStartHandler) {
            weakSelf.connectionWillStartHandler(weakOp.connection);
        }
    };
    
    op.connectionDidFinishHandler = ^(BOOL success, NSError *error) {
        if (weakSelf.connectionDidFinishHandler) {
            weakSelf.connectionDidFinishHandler(weakOp.connection, success, error);
        }
    };
    
    return op;
}

@end
