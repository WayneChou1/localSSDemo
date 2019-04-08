//
//  URLSchemeHandler.m
//  localSSDemo
//
//  Created by zhouzhiwei on 2018/12/21.
//  Copyright © 2018 zzw. All rights reserved.
//

#import "URLSchemeHandler.h"

static NSURLSession *session;

@interface URLSchemeHandler ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *task;

@end

@implementation URLSchemeHandler

+ (void)setLocalPort:(int)localPort {
    ssLocalPort = localPort;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    
    if (!session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//        configuration.TLSMaximumSupportedProtocol = kTLSProtocol1;
//        configuration.HTTPShouldUsePipelining =  YES;
        configuration.connectionProxyDictionary =
        @{(__bridge NSString *)kCFStreamPropertySOCKSProxyHost: @"127.0.0.1",
          (__bridge NSString *)kCFStreamPropertySOCKSProxyPort: @(ssLocalPort),
          };
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    
    self.task = [session dataTaskWithRequest:urlSchemeTask.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@ - %@ - %@", data,response, error);
        if (error) {
//            NSLog(@"session error:%@", error.localizedDescription);
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

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    //判断服务器返回的证书是否是服务器信任的
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        /*disposition：如何处理证书
         NSURLSessionAuthChallengePerformDefaultHandling:默认方式处理
         NSURLSessionAuthChallengeUseCredential：使用指定的证书    NSURLSessionAuthChallengeCancelAuthenticationChallenge：取消请求
         */
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
    }
    //安装证书
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end
