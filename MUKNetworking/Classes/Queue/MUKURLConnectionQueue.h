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

#import <Foundation/Foundation.h>
#import <MUKNetworking/MUKURLConnection.h>

extern NSInteger const MUKURLConnectionQueueDefaultMaxConcurrentConnections;

/**
 This class is used to enqueue a number of URL connections.
 
 Say you should download 20 images: it is not a good practice to
 start 20 connections together. You could feed you connections into
 a queue and use handlers like you usually do.
 */
@interface MUKURLConnectionQueue : NSObject
/** @name Properties */
/**
 Maximum number of concurrent conncection that the receiver can
 execute.
 
 Default: `MUKURLConnectionQueueDefaultMaxConcurrentConnections`,
 which means the value is determined dynamically by the 
 queue based on current system conditions.
 */
@property (nonatomic) NSInteger maximumConcurrentConnections;
/**
 Name of the queue.
 
 Names provide a way for you to identify your operation queues at
 run time.
 Tools may also use this name to provide additional 
 context during debugging or analysis of your code.
 */
@property (nonatomic, strong) NSString *name;
/**
 Modifies the execution of pending operations.
 
 If `YES`, the queue stops scheduling queued connections for
 execution.  
 If `NO`, the queue begins scheduling connections again.
 
 Suspending a queue prevents that queue from starting 
 additional connections. In other words, connections that are in the
 queue (or added to the queue later) and are not yet executing are
 prevented from starting until the queue is resumed. Suspending a 
 queue does not stop operations that are already running.
 */
@property (nonatomic, getter = isSuspended) BOOL suspended;

/** @name Handlers */
/**
 Handler called (in main queue) as connection is about to be started 
 by the queue.
 
 When handler returns, [MUKURLConnection start] is called on
 `connection` object.
 */
@property (nonatomic, copy) void (^connectionWillStartHandler)(MUKURLConnection *connection);
/**
 Handler called (in main queue) as connection has been removed
 from queue.
 */
@property (nonatomic, copy) void (^connectionDidFinishHandler)(MUKURLConnection *connection, BOOL success, NSError *error);

/** @name Methods */
/**
 Enqueue a connection.
 
 Once added, the specified connection remains in the queue until
 it finishes executing.
 
 @param connection Connection which will be enqueued.
 @exception NSInvalidArgumentException A connection object can be in
 at most one queue at a time and this method throws an 
 `NSInvalidArgumentException` exception if the connection is already 
 in another queue. Similarly, this method throws an
 `NSInvalidArgumentException` exception if the operation is 
 currently executing or has already finished executing.
 */
- (void)addConnection:(MUKURLConnection *)connection;
/**
 Adds the specified array of connections to the queue.
 
 Once added, the specified connections remain in the queue until
 they finish executing.
 
 @param connections The array of MUKURLConnection instances.
 @exception NSInvalidArgumentException A connection object can be in
 at most one connection queue at a time and cannot be added if it is 
 currently executing or finished. This method throws an 
 `NSInvalidArgumentException` exception if any of those error 
 conditions are true for any of the connections.
 */
- (void)addConnections:(NSArray *)connections;
/**
 Connections queued at this moment.
 @return Connections in the queue, which could be either executing
 or waiting to be executed.
 */
- (NSArray *)connections;

@end
