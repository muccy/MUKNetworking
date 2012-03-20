#import "MUKURLConnectionTests.h"
#import "MUKURLConnection.h"
#import "MUKTestURLProtocol.h"

@interface MUKURLConnectionTests ()
- (void)registerTestURLProtocol_;
- (void)unregisterTestURLProtocol_;

- (BOOL)waitForCompletion_:(BOOL *)done timeout_:(NSTimeInterval)timeout;
@end

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
    
    [self registerTestURLProtocol_];
    STAssertTrue([connection start], @"Connection should start having a valid request");
    [self unregisterTestURLProtocol_];
}

- (void)testCancellation {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    STAssertFalse([connection cancel], @"An unstarted connection should not be canceled");
    
    [self registerTestURLProtocol_];
    [connection start];
    STAssertTrue([connection cancel], @"A started connection should be canceled");
    [self unregisterTestURLProtocol_];
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
    __weak MUKURLConnection *weakConnection = connection;
    
    // Set handler to be tested
    connection.responseHandler = ^(NSURLResponse *response) {
        MUKURLConnection *strongConnection = weakConnection;
        
        // Perform tests
        STAssertEquals(response.expectedContentLength, expectedResponse.expectedContentLength, @"Received expected lenght should be equal to expected one");
        
        STAssertEquals(strongConnection.expectedBytesCount, expectedLen, @"Stored expected lenght should match");
        STAssertEquals(strongConnection.receivedBytesCount, (long long)0, @"Stored received bytes length should be 0 at this time");
        
        // Signal completion
        testsDone = YES;
    };
    
    // Perform request
    [self registerTestURLProtocol_];
    [MUKTestURLProtocol setResponseToProduce:expectedResponse];
    [connection start];
    
    BOOL done = [self waitForCompletion_:&testsDone timeout_:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    [self unregisterTestURLProtocol_];
}

#pragma mark - Private

- (void)registerTestURLProtocol_ {
    [MUKTestURLProtocol resetParameters];
    [NSURLProtocol registerClass:[MUKTestURLProtocol class]];
}

- (void)unregisterTestURLProtocol_ {
    [NSURLProtocol unregisterClass:[MUKTestURLProtocol class]];
}

- (BOOL)waitForCompletion_:(BOOL *)done timeout_:(NSTimeInterval)timeout {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        
        if ([timeoutDate timeIntervalSinceNow] < 0.0) {
            break;
        }
    } while (*done == NO);
    
    return *done;
}

@end
