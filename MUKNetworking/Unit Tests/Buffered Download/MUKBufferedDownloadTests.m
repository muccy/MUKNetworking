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


#import "MUKBufferedDownloadTests.h"
#import "MUKBufferedDownload.h"

@interface MUKBufferedDownloadTests ()
- (NSData *)mergedChunksToIndex_:(NSInteger)index chunks_:(NSArray *)chunks;
- (NSString *)stringForChunksToIndex_:(NSInteger)index chunks_:(NSArray *)chunks;
- (NSString *)bufferedString_:(MUKBufferedDownload *)download;
@end

@implementation MUKBufferedDownloadTests

- (void)testBuffering {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKBufferedDownload *download = [[MUKBufferedDownload alloc] initWithRequest:request];
    
    // Setup chunks
    NSData *firstChunk = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSData *secondChunk = [@"World" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *chunks = [NSArray arrayWithObjects:firstChunk, secondChunk, nil];
    
    __unsafe_unretained MUKBufferedDownload *weakDownload = download;
    
    __block NSInteger chunkIndex = 0;
    __block BOOL progressTestsDone = NO;
    download.progressHandler = ^(NSData *data, float quota) {        
        NSData *receivedChunks = [self mergedChunksToIndex_:chunkIndex chunks_:chunks];
        NSData *bufferedData = [weakDownload bufferedData];
        STAssertTrue([bufferedData isEqualToData:receivedChunks], @"Received data should be also buffered");
        
        chunkIndex++;
        
        if (chunkIndex >= [chunks count]) progressTestsDone = YES;
    }; // progressHandler
    
    __block BOOL completionTestsDone = NO;
    download.completionHandler = ^(BOOL success, NSError *error) {        
        NSData *receivedChunks = [self mergedChunksToIndex_:[chunks count]-1 chunks_:chunks];
        NSData *bufferedData = [weakDownload bufferedData];
        
        STAssertTrue([bufferedData isEqualToData:receivedChunks], @"Received data should be also buffered");

        STAssertEquals((long long)[bufferedData length], weakDownload.expectedBytesCount, @"Buffer length should match with expected data length");
        
        completionTestsDone = YES;
    }; // completionHandler

    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:chunks];
    
    [download start];
    
    BOOL done1 = [self waitForCompletion:&progressTestsDone timeout:5.0];
    BOOL done2 = [self waitForCompletion:&completionTestsDone timeout:5.0];
    
    if (!done1 || !done2) {
        STFail(@"Timeout");
    }
    
    STAssertEquals([[download bufferedData] length], (NSUInteger)0, @"No buffered data after failure handler returns");
    
    [self unregisterTestURLProtocol];
}

- (void)testError {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKBufferedDownload *download = [[MUKBufferedDownload alloc] initWithRequest:request];
    
    NSString *expectedString = @"Foo";
    NSData *expectedData = [expectedString dataUsingEncoding:NSUTF8StringEncoding];
    
    __block BOOL testsDone = NO;
    __unsafe_unretained MUKBufferedDownload *weakDownload = download;
    download.completionHandler = ^(BOOL success, NSError *error) {        
        STAssertFalse(success, @"Real error");
        STAssertNotNil(error, @"There should be an error");
        
        STAssertTrue([[weakDownload bufferedData] length] > 0, @"Something should be downloaded despite final error");
        
        testsDone = YES;
    };
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setErrorToProduce:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil]];
    [MUKTestURLProtocol setChunksToProduce:[NSArray arrayWithObject:expectedData]];
    
    [download start];
    
    BOOL done = [self waitForCompletion:&testsDone timeout:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    STAssertEquals([[download bufferedData] length], (NSUInteger)0, @"No buffered data after failure handler returns");
    
    [self unregisterTestURLProtocol];
}

- (void)testSuccess {
    // Setup connection
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    MUKBufferedDownload *download = [[MUKBufferedDownload alloc] initWithRequest:request];
    
    NSString *expectedString = @"Foo";
    NSData *expectedData = [expectedString dataUsingEncoding:NSUTF8StringEncoding];
    
    __block BOOL testsDone = NO;
    __unsafe_unretained MUKBufferedDownload *weakDownload = download;
    download.completionHandler = ^(BOOL success, NSError *error) {        
        STAssertTrue(success, @"True success");
        STAssertNil(error, @"No errors expected");
        
        STAssertTrue([[weakDownload bufferedData] isEqualToData:expectedData], @"Data downloaded");
        
        testsDone = YES;
    };
    
    [self registerTestURLProtocol];
    [MUKTestURLProtocol setChunksToProduce:[NSArray arrayWithObject:expectedData]];
    
    [download start];
    
    BOOL done = [self waitForCompletion:&testsDone timeout:5.0];
    if (!done) {
        STFail(@"Timeout");
    }
    
    STAssertEquals([[download bufferedData] length], (NSUInteger)0, @"No buffered data after success handler returns");
    
    [self unregisterTestURLProtocol];
}

#pragma mark - Private

- (NSData *)mergedChunksToIndex_:(NSInteger)index chunks_:(NSArray *)chunks {
    NSMutableData *mutData = [NSMutableData data];
    
    [chunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx > index) {
            *stop = YES;
            return;
        }
        
        [mutData appendData:obj];
    }];
    
    return mutData;
}

- (NSString *)stringForChunksToIndex_:(NSInteger)index chunks_:(NSArray *)chunks
{
    NSData *data = [self mergedChunksToIndex_:index chunks_:chunks];
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)bufferedString_:(MUKBufferedDownload *)download {
    return [[[NSString alloc] initWithData:[download bufferedData] encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
