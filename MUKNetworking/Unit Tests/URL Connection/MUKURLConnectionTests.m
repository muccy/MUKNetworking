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


#import "MUKURLConnectionTests.h"
#import "MUKURLConnection.h"

@implementation MUKURLConnectionTests

- (void)testActivity {
    MUKURLConnection *connection;
    connection = [[MUKURLConnection alloc] init];
    
    STAssertFalse([connection isActive], @"Connection should not be active after init");
}

- (void)testRequest {
    MUKURLConnection *connection;
    connection = [[MUKURLConnection alloc] init];
    
    STAssertFalse([connection start], @"Connection should not start without a request");
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    connection.request = request;
    STAssertEqualObjects(request, connection.request, @"Assigned request should be equal to the stored one");
    
    MUKURLConnection *connection2;
    connection2 = [[MUKURLConnection alloc] initWithRequest:request];
    STAssertEqualObjects(request, connection2.request, @"Request should be equal also using initializer");
    
    [self registerTestURLProtocol];
    STAssertTrue([connection start], @"Connection should start having a valid request");
    [self unregisterTestURLProtocol];
}

- (void)testCancellation {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    STAssertFalse([connection cancel], @"An unstarted connection should not be canceled");
    
    [self registerTestURLProtocol];
    [connection start];
    STAssertTrue([connection cancel], @"A started connection should be canceled");
    [self unregisterTestURLProtocol];
}

- (void)testResponse {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    // Expected values
    long long expectedLen = 22;
    NSURLResponse *expectedResponse = [[NSURLResponse alloc] initWithURL:[request URL] MIMEType:@"my_test" expectedContentLength:expectedLen textEncodingName:nil];
    
    // Tests to be performed
    __block BOOL testsDone = NO;
    __unsafe_unretained MUKURLConnection *weakConnection = connection;
    
    // Set handler to be tested
    connection.responseHandler = ^(NSURLResponse *response) {        
        // Perform tests
        STAssertEquals(response.expectedContentLength, expectedResponse.expectedContentLength, @"Received expected lenght should be equal to expected one");
        
        STAssertEquals(weakConnection.expectedBytesCount, expectedLen, @"Stored expected lenght should match");
        STAssertEquals(weakConnection.receivedBytesCount, (long long)0, @"Stored received bytes length should be 0 at this time");
        
        // Signal completion
        testsDone = YES;
    };
    
    // Perform request
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setResponseToProduce:expectedResponse];
    [connection start];
    
    BOOL done = [self waitForCompletion:&testsDone timeout:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    [self unregisterTestURLProtocol];
}

- (void)testProgress {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    // Create two test chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *testChunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    long long chunksLength = [firstChunk length] + [secondChunk length];
    
    __block BOOL testsDone = NO; 
    __block NSInteger chunkIndex = 0;
    __block long long receivedLength = 0;
    __unsafe_unretained MUKURLConnection *weakConnection = connection;
    connection.progressHandler = ^(NSData *data, float quota) {
        NSData *expectedChunk = [testChunks objectAtIndex:chunkIndex];
        
        // Verify data
        NSString *expectedString = [[NSString alloc] initWithData:expectedChunk encoding:NSUTF8StringEncoding];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        STAssertTrue([expectedChunk isEqualToData:data], @"Chunk (\"%@\") at index %i does not match expected one (\"%@\")", string, chunkIndex, expectedString);
        
        // Verify lengths
        receivedLength += [data length];
        STAssertEquals(receivedLength, weakConnection.receivedBytesCount, @"Received data length does not match");
        STAssertEquals(chunksLength, weakConnection.expectedBytesCount, @"Expected data length does not match");
        
        // Verify quota
        float q = (float)receivedLength/(float)chunksLength;
        STAssertEqualsWithAccuracy(quota, q, 0.001, @"Passed quota does not match with computed one");
        
        // Next
        chunkIndex++;
        
        // Tests complete
        if (chunkIndex >= [testChunks count]) testsDone = YES;
    };    
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:testChunks];
    
    [connection start];
    
    BOOL done = [self waitForCompletion:&testsDone timeout:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    [self unregisterTestURLProtocol];
}

- (void)testSuccess {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    // Create two test chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *testChunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    long long chunksLength = [firstChunk length] + [secondChunk length];
    
    __block BOOL testsDone = NO;
    __unsafe_unretained MUKURLConnection *weakConnection = connection;
    connection.completionHandler = ^(BOOL success, NSError *error) {        
        STAssertNil(error, @"No error when connection succeeds");
        STAssertTrue(success, @"Real success");
        
        STAssertEquals(weakConnection.receivedBytesCount, chunksLength, @"Received all data");
        STAssertEquals(weakConnection.receivedBytesCount, weakConnection.expectedBytesCount, @"Received all data");
        
        testsDone = YES;
    };
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:testChunks];
    
    [connection start];
    
    BOOL done = [self waitForCompletion:&testsDone timeout:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    STAssertFalse([connection isActive], @"Connection should not be active after success");
    STAssertEquals(connection.receivedBytesCount, (long long)0, @"Received bytes should be 0 when connection is not active");
    STAssertEquals(connection.expectedBytesCount, NSURLResponseUnknownLength, @"Expected bytes are unknown when connection is not active");
    
    [self unregisterTestURLProtocol];
}

- (void)testFailure {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    // Create two test chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *testChunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    
    NSError *expectedError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
    
    __block BOOL testsDone = NO;
    connection.completionHandler = ^(BOOL success, NSError *error) {        
        STAssertTrue(error.domain == expectedError.domain && error.code == expectedError.code, @"Error should match with expected one");
        STAssertFalse(success, @"Real failure");
        
        testsDone = YES;
    };
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setErrorToProduce:expectedError];
    [MUKTestURLProtocol setChunksToProduce:testChunks];
    
    [connection start];
    
    BOOL done = [self waitForCompletion:&testsDone timeout:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    STAssertFalse([connection isActive], @"Connection should not be active after failure");
    STAssertEquals(connection.receivedBytesCount, (long long)0, @"Received bytes should be 0 when connection is not active");
    STAssertEquals(connection.expectedBytesCount, NSURLResponseUnknownLength, @"Expected bytes are unknown when connection is not active");
    
    [self unregisterTestURLProtocol];
}

- (void)testEarlyFailure {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    NSError *expectedError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
    
    __block BOOL testsDone = NO;
    connection.completionHandler = ^(BOOL success, NSError *error) {        
        STAssertTrue(error.domain == expectedError.domain && error.code == expectedError.code, @"Error should match with expected one");
        STAssertFalse(success, @"Real failure");
        
        testsDone = YES;
    };
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setErrorToProduce:expectedError];
    
    [connection start];
    
    BOOL done = [self waitForCompletion:&testsDone timeout:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    STAssertFalse([connection isActive], @"Connection should not be active after failure");
    STAssertEquals(connection.receivedBytesCount, (long long)0, @"Received bytes should be 0 when connection is not active");
    STAssertEquals(connection.expectedBytesCount, NSURLResponseUnknownLength, @"Expected bytes are unknown when connection is not active");
    
    [self unregisterTestURLProtocol];
}

@end
