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

#import "MUKBufferedDownload.h"

@interface MUKBufferedDownload ()
@property (nonatomic, strong) NSMutableData *buffer_;

- (void)emptyBuffer_;
@end

@implementation MUKBufferedDownload
@synthesize buffer_;

- (void)dealloc {
    [self emptyBuffer_];
}

#pragma mark - Methods

- (NSData *)bufferedData {
    return [self.buffer_ copy];
}

#pragma mark - Overrides

- (BOOL)cancel {
    BOOL success = [super cancel];
    [self emptyBuffer_];
    return success;
}

- (void)didFailWithError:(NSError *)error {
    [super didFailWithError:error];
    [self emptyBuffer_];
}

- (void)didReceiveData:(NSData *)data {
    // Append data before to call handler
    [self.buffer_ appendData:data];
    [super didReceiveData:data];
}

- (void)didReceiveResponse:(NSURLResponse *)response {
    [super didReceiveResponse:response];
    
    NSUInteger capacity;
    if (self.expectedBytesCount != NSURLResponseUnknownLength) {
        capacity = self.expectedBytesCount;
    }
    else {
        capacity = 0;
    }
    
    self.buffer_ = [NSMutableData dataWithCapacity:capacity];
}

- (void)didFinishLoading {
    [super didFinishLoading];
    [self emptyBuffer_];
}

#pragma mark - Private

- (void)emptyBuffer_ {
    [self.buffer_ setLength:0];
    self.buffer_ = nil;
}

@end
