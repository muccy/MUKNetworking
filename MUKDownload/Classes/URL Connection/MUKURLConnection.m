#import "MUKURLConnection.h"

float const MUKURLConnectionUnknownQuota = -1.0f;

@interface MUKURLConnection ()
@property (nonatomic, strong) NSURLConnection *connection_;
@property (nonatomic, assign, readwrite) long long receivedBytesCount, expectedBytesCount;

- (void)nullifyInternalURLConnection_;
- (long long)expectedBytesCountInURLResponse_:(NSURLResponse *)response;
@end

@implementation MUKURLConnection
@synthesize request = request_;
@synthesize receivedBytesCount = receivedBytesCount_, expectedBytesCount = expectedBytesCount_;
@synthesize completionHandler = completionHandler_;
@synthesize responseHandler = responseHandler_;
@synthesize progressHandler = progressHandler_;
@synthesize redirectHandler = redirectHandler_;

@synthesize connection_;

- (id)init {
    self = [self initWithRequest:nil];
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request {
    self = [super init];
    if (self) {
        self.expectedBytesCount = NSURLResponseUnknownLength;
        self.request = request;
    }
    return self;
}

- (void)dealloc {
    [self nullifyInternalURLConnection_];
}

#pragma mark - Connection

- (BOOL)isActive {
    return (self.connection_ != nil);
}

- (BOOL)start {
    if ([self isActive] || self.request == nil) {
        return NO;
    }
    
    self.connection_ = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    [self.connection_ start];
    return YES;
}

- (BOOL)cancel {
    if ([self isActive] == NO) {
        return NO;
    }
    
    [self nullifyInternalURLConnection_];
    return YES;
}

#pragma mark - Callbacks

- (void)didFailWithError:(NSError *)error {
    self.completionHandler(NO, error);
    [self nullifyInternalURLConnection_];
}

- (void)didReceiveData:(NSData *)data {
    self.receivedBytesCount += [data length];

    float quota = MUKURLConnectionUnknownQuota;
    if (self.expectedBytesCount != NSURLResponseUnknownLength) {
        quota = ((float)self.receivedBytesCount/(float)self.expectedBytesCount);
    }
    
    self.progressHandler(data, quota);
}

- (void)didReceiveResponse:(NSURLResponse *)response {
    self.receivedBytesCount = 0;
    self.expectedBytesCount = [self expectedBytesCountInURLResponse_:response];
    self.responseHandler(response);
}

- (NSURLRequest *)willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (self.redirectHandler) {
        return self.redirectHandler(request, redirectResponse);
    }
    
    return request;
}

- (void)didFinishLoading {
    self.completionHandler(YES, nil);
    [self nullifyInternalURLConnection_];
}

#pragma mark - Private

- (void)nullifyInternalURLConnection_ {
    [self.connection_ cancel];
    self.connection_ = nil;
    
    self.receivedBytesCount = 0;
    self.expectedBytesCount = NSURLResponseUnknownLength;
}

- (long long)expectedBytesCountInURLResponse_:(NSURLResponse *)response {
    long long expected = NSURLResponseUnknownLength;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        expected = httpResponse.expectedContentLength;
    }
    
    return expected;
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (connection == self.connection_) {
        [self didFailWithError:error];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == self.connection_) {
        [self didReceiveData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection == self.connection_) {
        [self didReceiveResponse:response];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (connection == self.connection_) {
        return [self willSendRequest:request redirectResponse:redirectResponse];
    }
    
    return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (connection == self.connection_) {
        [self didFinishLoading];
    }
}

@end
