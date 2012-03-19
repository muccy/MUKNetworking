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
    
    STAssertTrue([connection start], @"Connection should start having a valid request");
}

- (void)testCancellation {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKURLConnection *connection = [[MUKURLConnection alloc] initWithRequest:request];
    
    STAssertFalse([connection cancel], @"An unstarted connection should not be canceled");
    
    [connection start];
    STAssertTrue([connection cancel], @"A started connection should be canceled");
}

@end
