//
//  URLSchemeHandler.m
//  localSSDemo
//
//  Created by zhouzhiwei on 2018/12/21.
//  Copyright © 2018 zzw. All rights reserved.
//

#import "URLSchemeHandler.h"

static NSURLSession *session;

@interface URLSchemeHandler ()

@property (nonatomic, strong) NSURLSessionDataTask *task;

@end

@implementation URLSchemeHandler

+ (void)setLocalPort:(int)localPort {
    ssLocalPort = localPort;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    
    if (!session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.TLSMaximumSupportedProtocol = kTLSProtocol1;
        configuration.connectionProxyDictionary =
        @{(__bridge NSString *)kCFStreamPropertySOCKSProxyHost: @"127.0.0.1",
          (__bridge NSString *)kCFStreamPropertySOCKSProxyPort: @(ssLocalPort),
          };
        session = [NSURLSession sessionWithConfiguration:configuration];
    }
    
    self.task = [session dataTaskWithRequest:urlSchemeTask.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //NSLog(@"%@ - %@", self.request.URL, error);
        if (error) {
            NSLog(@"error:%@", error.localizedDescription);
//            [urlSchemeTask didFailWithError:error];
        } else {
            [urlSchemeTask didReceiveResponse:response];
            [urlSchemeTask didReceiveData:data];
            [urlSchemeTask didFinish];
        }
    }];
    [self.task resume];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    [self.task cancel];
}

@end
