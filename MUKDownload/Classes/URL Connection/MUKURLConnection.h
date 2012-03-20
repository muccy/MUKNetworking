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
 */

#import <Foundation/Foundation.h>

typedef void (^MUKURLConnectionCompletionHandler)(BOOL success, NSError *error);
typedef void (^MUKURLConnectionProgressHandler)(NSData *chunk, float quota);
typedef void (^MUKURLConnectionResponseHandler)(NSURLResponse *response);
typedef NSURLRequest* (^MUKURLConnectionRedirectHandler)(NSURLRequest *request, NSURLResponse *redirectResponse);
             
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
/** @name Handlers */
/**
 An handler called as connection receives a response.
 
 `MUKURLConnectionResponseHandler` block takes only one parameter, `response`, 
 which is the URL response for the connection's request.
 
 @see didReceiveResponse:
 */
@property (nonatomic, copy) MUKURLConnectionResponseHandler responseHandler;
/**
 An handler called as connection receives a redirection, before to send new 
 request.
 
 `MUKURLConnectionRedirectHandler` block takes two parameters
 
 - `request`, the proposed redirected request.
 - `redirectResponse`, the URL response that caused the redirect.
 
 and returns the actual URL request to use in light of the redirection response.
 You can return nil in order to block redirection.
 
 @see willSendRequest:redirectResponse:
 */
@property (nonatomic, copy) MUKURLConnectionRedirectHandler redirectHandler;
/**
 An handler called as connection receives a chunk of data.
 
 `MUKURLConnectionProgressHandler` block takes two parameters
 
 - `chunk`, the newly available data.
 - `quota`, the progress expressed by a float from 0.0 to 1.0. It could be
 `MUKURLConnectionUnknownQuota` if quota could not be calculated.
 
 @see didReceiveData:
 */
@property (nonatomic, copy) MUKURLConnectionProgressHandler progressHandler;
/**
 An handler called as connection ends, both with success or with an error.
 
 `MUKURLConnectionCompletionHandler` block takes two parameters
 
 - `success`, which tells you if connection has terminated with success or not.
 - `error`, which could contain the error which caused the failure.
 
 @see didFailWithError:
 @see didFinishLoading
 */
@property (nonatomic, copy) MUKURLConnectionCompletionHandler completionHandler;
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
 @return YES if connection has been canceled.
 */
- (BOOL)cancel;
@end


@interface MUKURLConnection (Callback)
/**
 This callback signals when connection is failed.
 
 Default implementation of this method calls completionHandler with `success = NO`
 and deletes internal connection.
 
 This callback is called by internal NSURLConnection delegate implementation of
 `- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error`.
 
 @param error An error object containing details of why the connection failed to load the request successfully.
 */
- (void)didFailWithError:(NSError *)error;
/**
 This callback signals when connection receives a chunk of data.
 
 Default implementation of this method increments receivedBytesCount by `[data 
 length]`, calculates new `quota` with expectedBytesCount (or sets `quota` to 
 `MUKURLConnectionUnknownQuota`) and calls progressHandler.
 
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
 and `error = nil`. Then it deletes internal URL connection.
 
 This callback is called by internal NSURLConnection delegate implementation of
 `- (void)connectionDidFinishLoading:(NSURLConnection *)connection`.
 */
- (void)didFinishLoading;
@end