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

/**
 This class provides a basic, simple and lightweight wrapping to a NSURLConnection 
 instance.
 
 You create a request:
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:...];
 
 You create a connection:
    connection = [[MUKURLConnection alloc] initWithRequest:request];
 
 You can set callbacks using blocks, like:
    connection.progressHandler = ^(NSData *chunk, float quota) {
        NSLog(@"Connection downloaded %f of file...", quota * 100.0);
    };
 
 Then, you fire your connection:
    [connection start];
 
 What is more, this class optionally creates a buffer where chunks are saved: this
 is the default behaviour, that you could disable setting `usesBuffer` to `NO`.
 
 It empties internal buffer on cancellation, on errors (after calling completionHandler),
 on success (after calling completionHandler). It appends received data to internal
 buffer before to call progressHandler.
 
 @warning This class implements following NSURLConnection delegate methods:

     - (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
     - (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
     - (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
     - (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
     - (void)connectionDidFinishLoading:(NSURLConnection *)connection
 */

#import <Foundation/Foundation.h>
             
extern float const MUKURLConnectionUnknownQuota;

@interface MUKURLConnection : NSObject
/** @name Initializers */
/**
 Designated initializer
 @param request The URL request which will be performed invoking start.
 @return A connection ready to be started.
 */
- (id)initWithRequest:(NSURLRequest *)request;

/** @name Properties */
/**
 The URL request which will be performed invoking start.
 */
@property (nonatomic, strong) NSURLRequest *request;
/**
 It indicates if downloaded chunks of data should be saved into a buffer.
 
 *Default value*: `YES`.
 */
@property (nonatomic, assign) BOOL usesBuffer;
/**
 Connection runs when application is in background.
 
 Default is `NO`.
 
 When connection is started, a background task is begun. Background task is
 ended when connection finishes or it is cancelled.
 */
@property (nonatomic, assign) BOOL runsInBackground;
/**
 Number of bytes received by the connection.
 
 *Default value*: 0. When cancel is invoked this value is also reset to 0.
 */
@property (nonatomic, assign, readonly) long long receivedBytesCount;
/**
 Number of bytes expected by the connection.
 
 *Default value*: `NSURLResponseUnknownLength`. When cancel is invoked this value
 is also reset to `NSURLResponseUnknownLength`.
 
 @warning This value could be `NSURLResponseUnknownLength` also after a connection
 is estabilished.
 */
@property (nonatomic, assign, readonly) long long expectedBytesCount;
/**
 Custom object you could attach to connection.
 */
@property (nonatomic, strong) id userInfo;

/** @name Handlers */
/**
 An handler called as connection receives a response.
 
 `responseHandler` block takes only one parameter, `response`, 
 which is the URL response for the connection's request.
 
 @see didReceiveResponse:
 */
@property (nonatomic, copy) void (^responseHandler)(NSURLResponse *response);
/**
 An handler called as connection receives a redirection, before to send new 
 request.
 
 `redirectHandler` block takes two parameters:
 
 - `request`, the proposed redirected request.
 - `redirectResponse`, the URL response that caused the redirect.
 
 and returns the actual URL request to use in light of the redirection response.
 You can return nil in order to block redirection.
 
 @see willSendRequest:redirectResponse:
 */
@property (nonatomic, copy) NSURLRequest* (^redirectHandler)(NSURLRequest *request, NSURLResponse *redirectResponse);
/**
 An handler called as connection receives a chunk of data.
 
 `progressHandler` block takes two parameters:
 
 - `chunk`, the newly available data.
 - `quota`, the progress expressed by a float from 0.0 to 1.0. It could be
 `MUKURLConnectionUnknownQuota` if quota could not be calculated.
 
 @see didReceiveData:
 */
@property (nonatomic, copy) void (^progressHandler)(NSData *chunk, float quota);
/**
 An handler called as connection ends, both with success or with an error.
 
 `completionHandler` block takes two parameters:
 
 - `success`, which tells you if connection has terminated with success or not.
 - `error`, which could contain the error which caused the failure.
 
 @see didFailWithError:
 @see didFinishLoading
 */
@property (nonatomic, copy) void (^completionHandler)(BOOL success, NSError *error);
@end


@interface MUKURLConnection (Connection)
/**
 Query connection status.
 @return YES if connection is active.
 */
- (BOOL)isActive;
/**
 Start connection with given request.
 @return YES if connection has been started.
 */
- (BOOL)start;
/**
 Cancel running connection.
 
 If also empties buffer, if needed.
 
 @return YES if connection has been canceled.
 */
- (BOOL)cancel;
@end


@interface MUKURLConnection (Callback)
/**
 This callback signals when connection is failed.
 
 Default implementation of this method calls completionHandler with `success = NO`
 and deletes internal connection. If also empties buffer, if needed.
 
 This callback is called by internal NSURLConnection delegate implementation of
 `- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error`.
 
 @param error An error object containing details of why the connection failed to load the request successfully.
 */
- (void)didFailWithError:(NSError *)error;
/**
 This callback signals when connection receives a chunk of data.
 
 Default implementation of this method increments receivedBytesCount by `[data 
 length]`, calculates new `quota` with expectedBytesCount (or sets `quota` to 
 `MUKURLConnectionUnknownQuota`) and calls progressHandler. If also appends data
 to buffer, if needed.
 
 This callback is called by internal NSURLConnection delegate implementation of
 `- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data`.
 
 @param data The newly available data.
 */
- (void)didReceiveData:(NSData *)data;
/**
 This callback signals when connection receives a response.
 
 Default implementation of this method sets receivedBytesCount to 0, 
 expectedBytesCount to the right value (`NSURLResponseUnknownLength` if response
 does not contain a valid expected content length) and it calls responseHandler.
 If also creates buffer, if needed.
 
 This callback is called by internal NSURLConnection delegate implementation of
 `- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response`.
 
 @param response The URL response for the connection's request.
 */
- (void)didReceiveResponse:(NSURLResponse *)response;
/**
 This callback signals when connection receives a redirection response.
 
 Default implementation of this method calls redirectHandler. If no redirectHandler
 is set, it returns request as is.
 
 This callback is called by internal NSURLConnection delegate implementation of
 `- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse`.
 
 @param request The proposed redirected request.
 @param redirectResponse The URL response that caused the redirect.
 @return The actual URL request to use in light of the redirection response.
 You can return nil in order to block redirection.
 */
- (NSURLRequest *)willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
/**
 This callback signals when connection has finished to load successfully.
 
 Default implementation of this method calls completionHandler with `success = YES`
 and `error = nil`. Then it deletes internal URL connection. If also empties buffer, 
 if needed.
 
 This callback is called by internal NSURLConnection delegate implementation of
 `- (void)connectionDidFinishLoading:(NSURLConnection *)connection`.
 */
- (void)didFinishLoading;
@end


@interface MUKURLConnection (Buffer)
/**
 The data downloaded since the call to this method.
 @return A copy of the buffer.
 @warning Buffered data is available since until the connection is active. So
 you have a last chance to grab data in completionHandler.
 @warning Buffer is copied because real buffer data may disappear in order to 
 minimize memory footprint.
 */
- (NSData *)bufferedData;
/**
 Creates a new empty buffer to store data after an URL response.
 
 You could not override this method, because its implementation is
 fairly simple.
 
 @param response The URL response for the connection's request.
 @return A new buffer.
 */
- (NSMutableData *)newEmptyBufferForResponse:(NSURLResponse *)response;
/**
 Appends downloaded chunk to existing buffer.
 
 You could not override this method, because its implementation is
 fairly simple.
 
 @param data The newly available data.
 @param buffer Existing buffer.
 */
- (void)appendReceivedData:(NSData *)data toBuffer:(NSMutableData *)buffer;
/**
 Removes downloaded data stored in buffer.
 
 You could not override this method, because its implementation is
 fairly simple.
 
 @param buffer Existing buffer.
 @warning Buffer could be deallocated after this call.
 */
- (void)emptyBuffer:(NSMutableData *)buffer;
@end
