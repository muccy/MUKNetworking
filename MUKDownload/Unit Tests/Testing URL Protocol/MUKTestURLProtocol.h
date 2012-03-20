#import <Foundation/Foundation.h>

@interface MUKTestURLProtocol : NSURLProtocol
/*
 YES to fail withot a response
 */
+ (void)setFailsImmediately:(BOOL)failsImmediately;
/*
 nil to return a default response
 */
+ (void)setResponseToProduce:(NSURLResponse *)responseToProduce;
/*
 nil to make loading successful
 */
+ (void)setErrorToProduce:(NSError *)errorToProduce;
/*
 Insert some NSData items to simulate download
 */
+ (void)setChunksToProduce:(NSArray *)chunksToProduce;

/*
 Reset all parameters
 */
+ (void)resetParameters;
@end
