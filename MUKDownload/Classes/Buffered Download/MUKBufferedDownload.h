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
 This class is used in order to download a URL contents to a buffer.
 

 It overrides superclass as follows:
 
 It empties internal buffer on cancellation (after calling super implementation)
    - (BOOL)cancel
 
 It empties internal buffer on errors (after calling super implementation and, 
 thus, completionHandler):
    - (void)didFailWithError:(NSError *)error
 
 It empties internal buffer on success (after calling super implementation and, 
 thus, completionHandler):
    - (void)didFinishLoading
 
 It appends received data to internal buffer before to call super implementation
 and, thus, progressHandler:
    - (void)didReceiveData:(NSData *)data
 */

#import "MUKURLConnection.h"

@interface MUKBufferedDownload : MUKURLConnection
/**
 The data downloaded since the call to this method.
 @return A copy of the buffer.
 @warning Buffered data is available since until the connection is active. So
 you have a last chance to grab data in completionHandler.
 @warning Buffer is copied because real buffer data may disappear becuase of
 memory optimizations (see how superclass methods are overridden).
 */
- (NSData *)bufferedData;

@end
