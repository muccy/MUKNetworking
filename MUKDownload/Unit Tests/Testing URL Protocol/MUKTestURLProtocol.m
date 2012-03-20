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


#import "MUKTestURLProtocol.h"

@interface MUKTestURLProtocol ()
- (NSInteger)expectedContentLengthWithChunks_:(NSArray *)chunks;
- (BOOL)waitForCompletion_:(BOOL *)done timeout_:(NSTimeInterval)timeout;
@end

@implementation MUKTestURLProtocol

static BOOL MUKTestURLProtocolFailsImmediately = NO;
+ (void)setFailsImmediately:(BOOL)failsImmediately {
    MUKTestURLProtocolFailsImmediately = failsImmediately;
}

static NSURLResponse *MUKTestURLProtocolResponseToProduce = nil;
+ (void)setResponseToProduce:(NSURLResponse *)responseToProduce {
    MUKTestURLProtocolResponseToProduce = responseToProduce;
}

static NSError *MUKTestURLProtocolErrorToProduce = nil;
+ (void)setErrorToProduce:(NSError *)errorToProduce {
    MUKTestURLProtocolErrorToProduce = errorToProduce;
}

static NSArray *MUKTestURLProtocolChunksToProduce = nil;
+ (void)setChunksToProduce:(NSArray *)chunksToProduce {
    MUKTestURLProtocolChunksToProduce = chunksToProduce;
}

+ (void)resetParameters {
    MUKTestURLProtocolFailsImmediately = NO;
    MUKTestURLProtocolResponseToProduce = nil;
    MUKTestURLProtocolErrorToProduce = nil;
    MUKTestURLProtocolChunksToProduce = nil;
}

#pragma mark - Overrides

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSURLRequest *request = [self request];
    id client = [self client];
    
    if (MUKTestURLProtocolFailsImmediately) {
        [client URLProtocol:self didFailWithError:MUKTestURLProtocolErrorToProduce];
        return;
    }
    
    // Does not fail immediately
    // Compute an URL response    
    NSInteger expectedContentLenght = [self expectedContentLengthWithChunks_:MUKTestURLProtocolChunksToProduce];
    
    NSURLResponse *response;
    if (MUKTestURLProtocolResponseToProduce == nil) {
        response = [[NSURLResponse alloc] initWithURL:[request URL] MIMEType:@"plain/text" expectedContentLength:expectedContentLenght textEncodingName:@"utf-8"];
    }
    else {
        response = MUKTestURLProtocolResponseToProduce;
    }
    
    // Send response
    [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                    
    // Send some chunks if any
    [MUKTestURLProtocolChunksToProduce enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        [client URLProtocol:self didLoadData:obj];
        
        BOOL done = NO;
        [self waitForCompletion_:&done timeout_:0.2];
    }];
    
    // Success of failure
    if (MUKTestURLProtocolErrorToProduce) {
        [client URLProtocol:self didFailWithError:MUKTestURLProtocolErrorToProduce];
    }
    else {
        [client URLProtocolDidFinishLoading:self];
    }
}

- (void)stopLoading {
    //
}

#pragma mark - Private

- (NSInteger)expectedContentLengthWithChunks_:(NSArray *)chunks {
    __block NSInteger expectedContentLenght;
    
    if ([chunks count]) {
        expectedContentLenght = 0;
        [chunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
        {
            expectedContentLenght += [obj length];
        }];
    }
    else {
        expectedContentLenght = NSURLResponseUnknownLength;
    }
    
    return expectedContentLenght;
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
