//
//  WebViewController.m
//  localSSDemo
//
//  Created by zhouzhiwei on 2018/12/21.
//  Copyright © 2018 zzw. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>
#import "URLSchemeHandler.h"
#import "WKWebViewConfiguration+proxyConifg.h"

@interface WebViewController ()<WKNavigationDelegate>

@property (nonatomic,strong) WKWebView *webview;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"https"];
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    Class cls = NSClassFromString(@"WKBrowsingContextController");
    SEL sel = NSSelectorFromString(@"registerSchemeForCustomProtocol:");
    if ([(id)cls respondsToSelector:sel]) {
        // 把 http 和 https 请求交给 NSURLProtocol 处理
        [(id)cls performSelector:sel withObject:@"http"];
        [(id)cls performSelector:sel withObject:@"https"];
    }

    WKWebViewConfiguration *config = [WKWebViewConfiguration proxyConifg];
    
//    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    
    self.webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, width, height) configuration:config];
    self.webview.navigationDelegate = self;
    [self.view addSubview:self.webview];
    
    NSString *path = @"https://www.baidu.com/";
//    NSString *path = @"";
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:path]]];
}


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

@end
