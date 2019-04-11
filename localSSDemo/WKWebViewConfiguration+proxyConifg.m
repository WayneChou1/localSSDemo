//
//  WKWebViewConfiguration+proxyConifg.m
//  localSSDemo
//
//  Created by zhouzhiwei on 2018/12/21.
//  Copyright © 2018 zzw. All rights reserved.
//

#import "WKWebViewConfiguration+proxyConifg.h"
#import "URLSchemeHandler.h"

@implementation WKWebViewConfiguration (proxyConifg)

+ (WKWebViewConfiguration *)proxyConifg {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    URLSchemeHandler *handler = [[URLSchemeHandler alloc] init];
    if (@available(iOS 11.0, *)) {
        [config setURLSchemeHandler:handler forURLScheme:@"zzw"];
    } else {
        // Fallback on earlier versions
    }
    
    NSMutableDictionary *handlers = [config valueForKey:@"_urlSchemeHandlers"];
    handlers[@"http"] = handler;
    handlers[@"https"] = handler;
    return config;
}

@end
