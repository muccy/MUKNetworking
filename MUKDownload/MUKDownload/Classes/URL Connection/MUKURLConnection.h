#import <Foundation/Foundation.h>

typedef void (^MUKURLConnectionCompletionHandler)(BOOL success, NSError *error);
typedef void (^MUKURLConnectionProgressHandler)(NSData *chunk, float quota);
typedef void (^MUKURLConnectionResponseHandler)(NSURLResponse *response);
typedef NSURLRequest* (^MUKURLConnectionRedirectHandler)(NSURLRequest *request, NSURLResponse *redirectResponse);
             
extern float const MUKURLConnectionUnknownQuota;

@interface MUKURLConnection : NSObject
@property (nonatomic, strong) NSURLRequest *request;

- (id)initWithRequest:(NSURLRequest *)request;

@property (nonatomic, assign, readonly) long long receivedBytesCount, expectedBytesCount;

@property (nonatomic, copy) MUKURLConnectionResponseHandler responseHandler;
@property (nonatomic, copy) MUKURLConnectionRedirectHandler redirectHandler;
@property (nonatomic, copy) MUKURLConnectionProgressHandler progressHandler;
@property (nonatomic, copy) MUKURLConnectionCompletionHandler completionHandler;
@end


@interface MUKURLConnection (Connection)
- (BOOL)isActive;
- (BOOL)start;
- (BOOL)cancel;
@end


@interface MUKURLConnection (Callbacks)
- (void)didFailWithError:(NSError *)error;
- (void)didReceiveData:(NSData *)data;
- (void)didReceiveResponse:(NSURLResponse *)response;
- (NSURLRequest *)willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
- (void)didFinishLoading;
@end