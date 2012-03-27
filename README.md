MUKNetworking
===========
MUKNetworking is a simple, block-based, ARC-enabled library built around `NSURLConnection` for iOS 4+.
If you do need more complex solutions, please look at great frameworks like [AFNetworking].

Requirements
------------
* ARC enabled compiler
* Deployment target: iOS 4 or greater
* Base SDK: iOS 5 or greater
* Xcode 4 or greater

Installation
------------
*Thanks to [jverkoey iOS Framework]*.

#### Step 0: clone project from GitHub

#### Step 1: add MUKNetworking to your project
Drag or *Add To Files...* `MUKNetworking.xcodeproj` to your project.
<img src="http://i.imgur.com/iR0IM.png" />

Please remember not to create a copy of files while adding project: you only need a reference to it.
<img src="http://i.imgur.com/xJUfM.png" />

#### Step 2: make your project dependent
Click on your project and, then, your app target:
<img src="http://i.imgur.com/LiUR9.png" />

Add dependency clicking on + button in *Target Dependencies* pane and choosing static library target (`MUKNetworking`):
<img src="http://i.imgur.com/fiPyX.png" />

Link your project clicking on + button in *Link binary with Libraries* pane and choosing static library product (`libMUKNetworking.a`):
<img src="http://i.imgur.com/uyNVM.png" />

Your project, now, should be like this:
<img src="http://i.imgur.com/ayOVu.png" />

#### Step 3: import headers
You only need to write `#import <MUKNetworking/MUKNetworking.h>` when you need headers.
You can also import `MUKNetworking` headers in your `pch` file:
<img src="http://i.imgur.com/XcW35.png" />

Documentation
-------------
Build `MUKNetworkingDocumentation` target in order to install documentation in Xcode.
*Requirement*: [appledoc] awesome project.
*TODO*: online documentation.

Usage
-----
Look at included examples of two main classes:
* `MUKURLConnection`: base class and wrapper to `NSURLConnection`.
* `MUKBufferedDownload`: simple class to download data to a in-memory buffer.

Code snippet:

    __block MUKBufferedDownload *download = [[MUKBufferedDownload alloc] initWithRequest:...];

    download.completionHandler = ^(BOOL success, NSError *error) {
        if (success) {
            NSData *downloadedData = [download bufferedData];
            // Do something with data
        }
        else {
            NSLog(@"Error during download: %@", [error localizedDescription]);
        }
        
        download = nil;
    };
    
    [download start];

License
-------
Copyright (c) 2012, Marco Muccinelli
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of the <organization> nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



[AFNetworking]: https://github.com/AFNetworking/AFNetworking
[jverkoey iOS Framework]: https://github.com/jverkoey/iOS-Framework
[appledoc]: https://github.com/tomaz/appledoc
    