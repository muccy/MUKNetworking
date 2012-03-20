#import "MUKTestURLProtocol.h"

@interface MUKTestURLProtocol ()
- (NSInteger)expectedContentLengthWithChunks_:(NSArray *)chunks;
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

@end
