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
 
 Queue enforces [MUKURLConnection runsInBackground] choice by starting another
 background task before to add connection and ending that background task after
 connectionDidFinishHandler is invoked.
 
 @warning If you call [MUKURLConnection cancel], connection will be cancelled
 also from queue execution.
 @warning When queue is not deallocated until every connection finishes or it
 is cancelled.
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
 Handler called (on main queue) as connection is about to be started.
 
 @see willStartConnection:
 */
@property (nonatomic, copy) void (^connectionWillStartHandler)(MUKURLConnection *connection);
/**
 Handler called (on main queue) as connection has been removed from queue.
 
 @see didFinishConnection:cancelled:
 */
@property (nonatomic, copy) void (^connectionDidFinishHandler)(MUKURLConnection *connection, BOOL cancelled);

/** @name Methods */
/**
 Enqueue a connection.
 
 Once added, the specified connection remains in the queue until
 it finishes executing.
 
 If [MUKURLConnection runsInBackground] is `YES`, a background task is started
 in order to call connectionDidFinishHandler before app is suspended.
 
 @param connection Connection which will be enqueued.
 @return `YES` if connection can be inserted. Mind that a connection
 object can be in at most one queue at a time. Similarly, this method returns 
 `NO` if the connection is currently executing or has already finished 
 executing.
 */
- (BOOL)addConnection:(MUKURLConnection *)connection;
/**
 Adds the specified array of connections to the queue.
 
 Once added, the specified connections remain in the queue until
 they finish executing.
 
 If some [MUKURLConnection runsInBackground] are `YES`, a background tasks are
 started in order to call connectionDidFinishHandler before app is suspended.
 
 @param connections The array of MUKURLConnection instances.
 @return `YES` if connections can be inserted. Mind that a connection
 object can be in at most one queue at a time. Similarly, this method returns 
 `NO` if any of the connections is currently executing or has already finished 
 executing.
 */
- (BOOL)addConnections:(NSArray *)connections;
/**
 Connections queued at this moment.
 @return Connections in the queue, which could be either executing
 or waiting to be executed.
 */
- (NSArray *)connections;
/**
 Cancels all queued and executing connections.
 
 This method sends a cancel message to all connections currently in the queue.
 
 @warning didFinishConnection:cancelled: is not called synchronously in this method,
 but in the moment connection is put outside the queue.
 */
- (void)cancelAllConnections;
@end


@interface MUKURLConnectionQueue (Callbacks)
/**
 Callback called (on main dispatch queue) as connection is about to be started 
 by the connection queue.
 
 When callback returns, [MUKURLConnection start] is called on connection object.
 
 Default implementation calls connectionWillStartHandler.
 
 @param connection The connection which will be started.
 */
- (void)willStartConnection:(MUKURLConnection *)connection;
/**
 Callback called (on main dispatch queue) as connection has been removed from queue.
 
 `cancelled` is `YES` if connection has been removed from queue after cancellation.
 
 Execution is guaranteed in background, because task is ended after callback
 returns.
 
 Default implementation calls connectionDidFinishHandler.
 
 @param connection The connection which has been removed from queue.
 @param cancelled `YES` if connection has been removed from queue because of
 a cancellation.
 @warning Connection buffer could be already empty when this handler is called.
 Please keep using [MUKURLConnection completionHandler]. This callback is useful
 to observe queue status.
 */
- (void)didFinishConnection:(MUKURLConnection *)connection cancelled:(BOOL)cancelled;
@end
