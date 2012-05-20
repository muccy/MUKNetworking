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

#import "MUKURLConnectionQueueTests.h"
#import "MUKURLConnectionQueue.h"

#define kTimeout    2.0

@interface MockQueue_ : MUKURLConnectionQueue
@property (nonatomic) BOOL *objectDealloced;
@property (nonatomic) NSInteger *didFinishConnectionCallsCount;
@end

@implementation MockQueue_
@synthesize objectDealloced;
@synthesize didFinishConnectionCallsCount;

- (void)dealloc {
    *(self.objectDealloced) = YES;
}

- (void)didFinishConnection:(MUKURLConnection *)connection cancelled:(BOOL)cancelled
{
    [super didFinishConnection:connection cancelled:cancelled];
    (*(self.didFinishConnectionCallsCount))++;
}

@end

#pragma mark - 
#pragma mark - 

@implementation MUKURLConnectionQueueTests

- (void)testEnqueueing {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection1 = [[MUKURLConnection alloc] initWithRequest:request];
    connection1.runsInBackground = YES;
    MUKURLConnection *connection2 = [[MUKURLConnection alloc] initWithRequest:request];
    NSInteger const kConnectionsCount = 2;
    
    // Setup chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *chunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    
    __unsafe_unretained MUKURLConnection *weakConnection1 = connection1;
    __unsafe_unretained MUKURLConnection *weakConnection2 = connection2;
    
    __block BOOL completion1TestsDone = NO;
    __block NSDate *completion1Date = nil;
    connection1.completionHandler = ^(BOOL success, NSError *error) {        
        NSData *bufferedData = [weakConnection1 bufferedData];
        STAssertEquals((long long)[bufferedData length], weakConnection1.expectedBytesCount, @"Buffer length should match with expected data length");
        completion1Date = [NSDate date];
        completion1TestsDone = YES;
    }; // completionHandler 1
    
    __block BOOL completion2TestsDone = NO;
    __block NSDate *completion2Date = nil;
    connection2.completionHandler = ^(BOOL success, NSError *error) {        
        NSData *bufferedData = [weakConnection2 bufferedData];
        STAssertEquals((long long)[bufferedData length], weakConnection2.expectedBytesCount, @"Buffer length should match with expected data length");
        completion2Date = [NSDate date];
        completion2TestsDone = YES;
    }; // completionHandler 2
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:chunks];
    
    // Create a queue
    MUKURLConnectionQueue *queue = [[MUKURLConnectionQueue alloc] init];
    queue.maximumConcurrentConnections = 1;
    queue.name = @"it.melive.mukit.mukknetworking.tests";
    
    __block MUKURLConnection *lastWillStartConnection = nil;
    __block NSInteger willStartConnectionCount = 0;
    queue.connectionWillStartHandler = ^(MUKURLConnection *conn) {
        lastWillStartConnection = conn;
        willStartConnectionCount++;
    };
    
    __block MUKURLConnection *lastDidFinishConnection = nil;
    __block NSInteger didFinishConnectionCount = 0;
    __block BOOL allConnectionsStopped = NO;
    queue.connectionDidFinishHandler = ^(MUKURLConnection *conn, BOOL cancelled)
    {
        STAssertFalse(cancelled, @"Not cancelled");
        lastDidFinishConnection = conn;
        didFinishConnectionCount++;
        allConnectionsStopped = (didFinishConnectionCount == kConnectionsCount);
    };
    
    // Add connections
    [queue addConnection:connection1];
    [queue addConnection:connection2];
    
    BOOL done1 = [self waitForCompletion:&completion1TestsDone timeout:kTimeout];
    BOOL done2 = [self waitForCompletion:&completion2TestsDone timeout:kTimeout];
    if (!done1 || !done2) STFail(@"Timeout");
    
    STAssertTrue([completion2Date compare:completion1Date] == NSOrderedDescending, nil);
    
    BOOL done3 = [self waitForCompletion:&allConnectionsStopped timeout:kTimeout];
    if (!done3) STFail(@"Timeout");
    
    STAssertEquals((NSUInteger)0, [[queue connections] count], @"No more connections enqueued");
    STAssertEquals(kConnectionsCount, willStartConnectionCount, @"%i connections dequeued", willStartConnectionCount);
    STAssertEquals(kConnectionsCount, didFinishConnectionCount, @"%i connections dequeued", didFinishConnectionCount);
    STAssertEqualObjects(lastWillStartConnection, connection2, @"Connection2 after Connection1");
    STAssertEqualObjects(lastDidFinishConnection, connection2, @"Connection2 after Connection2");
    
    [self unregisterTestURLProtocol];
    queue.connectionWillStartHandler = nil;
    queue.connectionDidFinishHandler = nil;
}

- (void)testEnqueueingGroup {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection1 = [[MUKURLConnection alloc] initWithRequest:request];
    MUKURLConnection *connection2 = [[MUKURLConnection alloc] initWithRequest:request];
    connection2.runsInBackground = YES;
    NSArray *connections = [[NSArray alloc] initWithObjects:connection1, connection2, nil];
    NSInteger const kConnectionsCount = 2;
    
    // Setup chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *chunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    
    __unsafe_unretained MUKURLConnection *weakConnection1 = connection1;
    __unsafe_unretained MUKURLConnection *weakConnection2 = connection2;
    
    __block BOOL completion1TestsDone = NO;
    __block NSDate *completion1Date = nil;
    connection1.completionHandler = ^(BOOL success, NSError *error) {        
        NSData *bufferedData = [weakConnection1 bufferedData];
        STAssertEquals((long long)[bufferedData length], weakConnection1.expectedBytesCount, @"Buffer length should match with expected data length");
        completion1Date = [NSDate date];
        completion1TestsDone = YES;
    }; // completionHandler 1
    
    __block BOOL completion2TestsDone = NO;
    __block NSDate *completion2Date = nil;
    connection2.completionHandler = ^(BOOL success, NSError *error) {        
        NSData *bufferedData = [weakConnection2 bufferedData];
        STAssertEquals((long long)[bufferedData length], weakConnection2.expectedBytesCount, @"Buffer length should match with expected data length");
        completion2Date = [NSDate date];
        completion2TestsDone = YES;
    }; // completionHandler 2
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:chunks];
    
    // Create a queue
    MUKURLConnectionQueue *queue = [[MUKURLConnectionQueue alloc] init];
    queue.maximumConcurrentConnections = 1;
    queue.name = @"it.melive.mukit.mukknetworking.tests";
    
    __block MUKURLConnection *lastWillStartConnection = nil;
    __block NSInteger willStartConnectionCount = 0;
    queue.connectionWillStartHandler = ^(MUKURLConnection *conn) {
        lastWillStartConnection = conn;
        willStartConnectionCount++;
    };
    
    __block MUKURLConnection *lastDidFinishConnection = nil;
    __block NSInteger didFinishConnectionCount = 0;
    __block BOOL allConnectionsStopped = NO;
    queue.connectionDidFinishHandler = ^(MUKURLConnection *conn, BOOL cancelled)
    {
        STAssertFalse(cancelled, @"Not cancelled");
        lastDidFinishConnection = conn;
        didFinishConnectionCount++;
        allConnectionsStopped = (didFinishConnectionCount == kConnectionsCount);
    };
    
    // Add connections
    [queue addConnections:connections];
    
    BOOL done1 = [self waitForCompletion:&completion1TestsDone timeout:kTimeout];
    BOOL done2 = [self waitForCompletion:&completion2TestsDone timeout:kTimeout];
    if (!done1 || !done2) STFail(@"Timeout");
    
    STAssertTrue([completion2Date compare:completion1Date] == NSOrderedDescending, nil);
    
    BOOL done3 = [self waitForCompletion:&allConnectionsStopped timeout:kTimeout];
    if (!done3) STFail(@"Timeout");
    
    STAssertEquals((NSUInteger)0, [[queue connections] count], @"No more connections enqueued");
    STAssertEquals(kConnectionsCount, willStartConnectionCount, @"%i connections dequeued", willStartConnectionCount);
    STAssertEquals(kConnectionsCount, didFinishConnectionCount, @"%i connections dequeued", didFinishConnectionCount);
    STAssertEqualObjects(lastWillStartConnection, connection2, @"Connection2 after Connection1");
    STAssertEqualObjects(lastDidFinishConnection, connection2, @"Connection2 after Connection1");
    
    [self unregisterTestURLProtocol];
    queue.connectionWillStartHandler = nil;
    queue.connectionDidFinishHandler = nil;
}

- (void)testConnectionCancellation {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection1 = [[MUKURLConnection alloc] initWithRequest:request];
    MUKURLConnection *connection2 = [[MUKURLConnection alloc] initWithRequest:request];
    connection2.runsInBackground = YES;
    MUKURLConnection *cancelledConnection = connection2;
    NSArray *connections = [[NSArray alloc] initWithObjects:connection1, connection2, nil];
    NSInteger const kConnectionsCount = 2;
    
    // Setup chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *chunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:chunks];
    
    // Create a queue
    MUKURLConnectionQueue *queue = [[MUKURLConnectionQueue alloc] init];
    queue.maximumConcurrentConnections = 1;
    queue.name = @"it.melive.mukit.mukknetworking.tests";
    
    __block MUKURLConnection *lastDidFinishConnection = nil;
    __block NSInteger didFinishConnectionCount = 0;
    __block BOOL allConnectionsStopped = NO;
    __block BOOL connectionCancellationSignaled = NO;
    queue.connectionDidFinishHandler = ^(MUKURLConnection *conn, BOOL cancelled)
    {        
        if (cancelledConnection == conn) {
            STAssertTrue(cancelled, @"Cancelled");
            connectionCancellationSignaled = cancelled;
        }
        else {
            STAssertFalse(cancelled, @"Not cancelled");
        }
        
        lastDidFinishConnection = conn;
        didFinishConnectionCount++;
        allConnectionsStopped = (didFinishConnectionCount == kConnectionsCount);
    };
    
    // Add connections
    queue.suspended = YES;
    [queue addConnections:connections];
    
    // Cancel
    [cancelledConnection cancel];
    queue.suspended = NO;
    
    BOOL done = [self waitForCompletion:&allConnectionsStopped timeout:kTimeout];
    if (!done) STFail(@"Timeout");
    
    STAssertEquals((NSUInteger)0, [[queue connections] count], @"No more connections enqueued");
    STAssertEquals(kConnectionsCount, didFinishConnectionCount, @"%i connections dequeued", didFinishConnectionCount);
    STAssertEqualObjects(lastDidFinishConnection, connection2, @"Connection2 after Connection1");
    STAssertTrue(connectionCancellationSignaled, @"Connection2 signaled");
    
    [self unregisterTestURLProtocol];
    queue.connectionWillStartHandler = nil;
    queue.connectionDidFinishHandler = nil;
}

- (void)testAllConnectionsCancellation {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection1 = [[MUKURLConnection alloc] initWithRequest:request];
    connection1.runsInBackground = YES;
    MUKURLConnection *connection2 = [[MUKURLConnection alloc] initWithRequest:request];
    NSArray *connections = [[NSArray alloc] initWithObjects:connection1, connection2, nil];
    NSInteger const kConnectionsCount = 2;
    
    // Setup chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *chunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:chunks];
    
    // Create a queue
    MUKURLConnectionQueue *queue = [[MUKURLConnectionQueue alloc] init];
    queue.maximumConcurrentConnections = 1;
    queue.name = @"it.melive.mukit.mukknetworking.tests";
    
    __block MUKURLConnection *lastDidFinishConnection = nil;
    __block NSInteger didFinishConnectionCount = 0;
    __block BOOL allConnectionsStopped = NO;
    queue.connectionDidFinishHandler = ^(MUKURLConnection *conn, BOOL cancelled)
    {        
        STAssertTrue(cancelled, @"Cancelled");
        
        lastDidFinishConnection = conn;
        didFinishConnectionCount++;
        allConnectionsStopped = (didFinishConnectionCount == kConnectionsCount);
    };
    
    // Add connections
    queue.suspended = YES;
    [queue addConnections:connections];
    
    // Cancel
    [queue cancelAllConnections];
    queue.suspended = NO;
    
    BOOL done = [self waitForCompletion:&allConnectionsStopped timeout:kTimeout];
    if (!done) STFail(@"Timeout");
    
    STAssertEquals((NSUInteger)0, [[queue connections] count], @"No more connections enqueued");
    STAssertEquals(kConnectionsCount, didFinishConnectionCount, @"%i connections dequeued", didFinishConnectionCount);
    STAssertEqualObjects(lastDidFinishConnection, connection2, @"Connection2 after Connection1");
    
    [self unregisterTestURLProtocol];
    queue.connectionWillStartHandler = nil;
    queue.connectionDidFinishHandler = nil;
}

- (void)testQueueDeallocation {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection1 = [[MUKURLConnection alloc] initWithRequest:request];
    connection1.runsInBackground = YES;
    MUKURLConnection *connection2 = [[MUKURLConnection alloc] initWithRequest:request];
    NSArray *connections = [[NSArray alloc] initWithObjects:connection1, connection2, nil];
    NSInteger const kConnectionsCount = 2;
    
    // Setup chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *chunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:chunks];
    
    // Create a queue
    MockQueue_ *queue = [[MockQueue_ alloc] init];
    queue.maximumConcurrentConnections = 1;
    queue.name = @"it.melive.mukit.mukknetworking.tests";
    
    NSInteger didFinishCount = 0;
    queue.didFinishConnectionCallsCount = &didFinishCount;
    
    BOOL queueDealloced = NO;
    queue.objectDealloced = &queueDealloced;
    
    queue.connectionWillStartHandler = ^(MUKURLConnection *conn) {
        //
    };
    
    queue.connectionDidFinishHandler = ^(MUKURLConnection *conn, BOOL cancelled)
    {        
        //
    };
    
    // Add connections
    queue.suspended = YES;
    [queue addConnections:connections];
    
    // Lose strong pointer to queue
    queue.suspended = NO;
    queue.connectionWillStartHandler = nil;
    queue.connectionDidFinishHandler = nil;
    queue = nil;
    
    // Wait for timeout
    [self waitForCompletion:&queueDealloced timeout:kTimeout*5.0];

    STAssertEquals(kConnectionsCount, didFinishCount, @"%i connections dequeued", didFinishCount);
    STAssertTrue(queueDealloced, @"Queue deallocated");
    
    [self unregisterTestURLProtocol];
}

- (void)testConnectionsList {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    
    NSArray *connections = [[NSArray alloc] initWithObjects:
                            [[MUKURLConnection alloc] initWithRequest:request],
                            [[MUKURLConnection alloc] initWithRequest:request],
                            nil];
    
    MUKURLConnectionQueue *queue = [[MUKURLConnectionQueue alloc] init];
    queue.suspended = YES;
    
    [queue addConnections:connections];
    
    __block NSUInteger count = 0;
    [[queue connections] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        MUKURLConnection *expectedConnection = [connections objectAtIndex:idx];
        STAssertEqualObjects(expectedConnection, obj, nil);
        count++;
    }];
    
    STAssertEquals(count, [connections count], nil);
}

@end
