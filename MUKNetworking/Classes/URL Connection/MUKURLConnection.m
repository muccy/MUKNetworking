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
#import "MUKURLConnection_Queue.h"
#import "MUKURLConnection_Background.h"

float const MUKURLConnectionUnknownQuota = -1.0f;

@interface MUKURLConnection ()
@property (nonatomic, strong) NSURLConnection *connection_;
@property (nonatomic, assign, readwrite) long long receivedBytesCount, expectedBytesCount;
@property (nonatomic, strong) NSMutableData *buffer_;

- (void)nullifyInternalURLConnection_;

- (void)createBufferIfNeeded_:(NSURLResponse *)response;
- (void)appendDataToBufferIfNeeded_:(NSData *)data;
- (void)emptyBufferIfNeeded_;
@end

@implementation MUKURLConnection
@synthesize request = request_;
@synthesize usesBuffer = usesBuffer_;
@synthesize runsInBackground = runsInBackground_;
@synthesize receivedBytesCount = receivedBytesCount_, expectedBytesCount = expectedBytesCount_;
@synthesize completionHandler = completionHandler_;
@synthesize responseHandler = responseHandler_;
@synthesize progressHandler = progressHandler_;
@synthesize redirectHandler = redirectHandler_;

@synthesize connection_;
@synthesize buffer_;
@synthesize backgroundTaskIdentifier_ = backgroundTaskIdentifier__;

@synthesize operationCompletionHandler_ = operationCompletionHandler__;
@synthesize operationCancelHandler_ = operationCancelHandler__;


- (id)init {
    self = [self initWithRequest:nil];
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request {
    self = [super init];
    if (self) {
        self.expectedBytesCount = NSURLResponseUnknownLength;
        self.request = request;
        self.usesBuffer = YES;
        self.backgroundTaskIdentifier_ = UIBackgroundTaskInvalid;
    }
    return self;
}

- (void)dealloc {
    [self nullifyInternalURLConnection_];
    [self emptyBufferIfNeeded_];
    [self endBackgroundTaskIfNeeded_];
}

#pragma mark - Connection

- (BOOL)isActive {
    return (self.connection_ != nil);
}

- (BOOL)start {
    if ([self isActive] || self.request == nil) {
        return NO;
    }
    
    [self beginBackgroundTaskIfNeeded_];
    self.connection_ = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    
    return (self.connection_ != nil);
}

- (BOOL)cancel {    
    BOOL success;
    
    if ([self isActive]) {
        [self nullifyInternalURLConnection_];
        [self emptyBufferIfNeeded_];
        
        success = YES;
    }
    else {
        success = NO;
    }
    
    /*
     Call operation after every other task.
     In this way, connection is retained by operation for sure, not 
     depending to race conditions.
     */
    if (self.operationCancelHandler_) {
        self.operationCancelHandler_();
    }
    
    [self endBackgroundTaskIfNeeded_];

    return success;
}

#pragma mark - Callbacks

- (void)didFailWithError:(NSError *)error {
    if (self.completionHandler) {
        self.completionHandler(NO, error);
    }
    
    [self nullifyInternalURLConnection_];
    [self emptyBufferIfNeeded_];
    
    /*
     Call operation after every other task.
     In this way, connection is retained by operation for sure, not 
     depending to race conditions.
     */
    if (self.operationCompletionHandler_) {
        self.operationCompletionHandler_(NO, error);
    }
    
    [self endBackgroundTaskIfNeeded_];
}

- (void)didReceiveData:(NSData *)data {
    self.receivedBytesCount += [data length];

    float quota = MUKURLConnectionUnknownQuota;
    if (self.expectedBytesCount != NSURLResponseUnknownLength) {
        quota = ((float)self.receivedBytesCount/(float)self.expectedBytesCount);
    }
    
    [self appendDataToBufferIfNeeded_:data];
    if (self.progressHandler) self.progressHandler(data, quota);
}

- (void)didReceiveResponse:(NSURLResponse *)response {
    self.receivedBytesCount = 0;
    self.expectedBytesCount = response.expectedContentLength;
    [self createBufferIfNeeded_:response];
    
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
    if (self.completionHandler) {
        self.completionHandler(YES, nil);
    }
    
    [self nullifyInternalURLConnection_];
    [self emptyBufferIfNeeded_];
    
    /*
     Call operation after every other task.
     In this way, connection is retained by operation for sure, not 
     depending to race conditions.
     */
    if (self.operationCompletionHandler_) {
        self.operationCompletionHandler_(YES, nil);
    }
    
    [self endBackgroundTaskIfNeeded_];
}

#pragma mark - Buffer

- (NSData *)bufferedData {
    return [self.buffer_ copy];
}

- (NSMutableData *)newEmptyBufferForResponse:(NSURLResponse *)response {
    NSUInteger capacity;
    if (self.expectedBytesCount != NSURLResponseUnknownLength) {
        capacity = self.expectedBytesCount;
    }
    else {
        capacity = 0;
    }
    
    return [[NSMutableData alloc] initWithCapacity:capacity];
}

- (void)appendReceivedData:(NSData *)data toBuffer:(NSMutableData *)buffer {
    [buffer appendData:data];
}

- (void)emptyBuffer:(NSMutableData *)buffer {
    [buffer setLength:0];
}

#pragma mark - Private

- (void)nullifyInternalURLConnection_ {
    [self.connection_ cancel];
    self.connection_ = nil;
    
    self.receivedBytesCount = 0;
    self.expectedBytesCount = NSURLResponseUnknownLength;
}

- (void)createBufferIfNeeded_:(NSURLResponse *)response {
    if (self.usesBuffer) {
        self.buffer_ = [self newEmptyBufferForResponse:response];
    }
}

- (void)appendDataToBufferIfNeeded_:(NSData *)data {
    if (self.usesBuffer) {
        [self appendReceivedData:data toBuffer:self.buffer_];
    }
}

- (void)emptyBufferIfNeeded_ {
    if (self.usesBuffer) {
        [self emptyBuffer:self.buffer_];
        self.buffer_ = nil;
    }
}

#pragma mark - Private: Background

- (void)beginBackgroundTaskIfNeeded_ {
    if (self.runsInBackground) {
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            if (self.backgroundTaskIdentifier_ == UIBackgroundTaskInvalid) 
            {
                UIApplication *app = [UIApplication sharedApplication];
                self.backgroundTaskIdentifier_ = [app beginBackgroundTaskWithExpirationHandler:^
                {
                    [self endBackgroundTaskIfNeeded_];
                }];
            } // if UIBackgroundTaskInvalid
        } // if isMultitaskingSupported
    } // if runsInBackground
}

- (void)endBackgroundTaskIfNeeded_ {
    if (self.backgroundTaskIdentifier_ != UIBackgroundTaskInvalid) {
        UIApplication *app = [UIApplication sharedApplication];
        [app endBackgroundTask:self.backgroundTaskIdentifier_];
        self.backgroundTaskIdentifier_ = UIBackgroundTaskInvalid;
    }
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
