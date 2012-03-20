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


#import "MUKURLConnection.h"

float const MUKURLConnectionUnknownQuota = -1.0f;

@interface MUKURLConnection ()
@property (nonatomic, strong) NSURLConnection *connection_;
@property (nonatomic, assign, readwrite) long long receivedBytesCount, expectedBytesCount;

- (void)nullifyInternalURLConnection_;
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
    
    return (self.connection_ != nil);
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
    if (self.completionHandler) self.completionHandler(NO, error);
    [self nullifyInternalURLConnection_];
}

- (void)didReceiveData:(NSData *)data {
    self.receivedBytesCount += [data length];

    float quota = MUKURLConnectionUnknownQuota;
    if (self.expectedBytesCount != NSURLResponseUnknownLength) {
        quota = ((float)self.receivedBytesCount/(float)self.expectedBytesCount);
    }
    
    if (self.progressHandler) self.progressHandler(data, quota);
}

- (void)didReceiveResponse:(NSURLResponse *)response {
    self.receivedBytesCount = 0;
    self.expectedBytesCount = response.expectedContentLength;
    if (self.responseHandler) self.responseHandler(response);
}

- (NSURLRequest *)willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (self.redirectHandler) {
        return self.redirectHandler(request, redirectResponse);
    }
    
    return request;
}

- (void)didFinishLoading {
    if (self.completionHandler) self.completionHandler(YES, nil);
    [self nullifyInternalURLConnection_];
}

#pragma mark - Private

- (void)nullifyInternalURLConnection_ {
    [self.connection_ cancel];
    self.connection_ = nil;
    
    self.receivedBytesCount = 0;
    self.expectedBytesCount = NSURLResponseUnknownLength;
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
