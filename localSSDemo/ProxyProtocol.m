//
//  ProxyProtocol.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ProxyProtocol.h"

static NSURLSession *session;

@interface ProxyProtocol() <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *task;

@end

@implementation ProxyProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

+ (void)setLocalPort:(NSInteger)localPort {
    ssLocalPort = localPort;
}

- (void)startLoading
{
    if (!session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.HTTPMaximumConnectionsPerHost = 10;
        configuration.connectionProxyDictionary =
        @{(NSString *)kCFStreamPropertySOCKSProxyHost: @"127.0.0.1",
          (NSString *)kCFStreamPropertySOCKSProxyPort: @(ssLocalPort)};
        session = [NSURLSession sessionWithConfiguration:configuration];
    }
    
    __weak typeof(self)weakSelf = self;
    self.task = [session dataTaskWithRequest:self.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //NSLog(@"%@ - %@", self.request.URL, error);
        if (error) {
            [weakSelf.client URLProtocol:weakSelf didFailWithError:error];
        } else {
            [weakSelf.client URLProtocol:weakSelf didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
            [weakSelf.client URLProtocol:weakSelf didLoadData:data];
            [weakSelf.client URLProtocolDidFinishLoading:weakSelf];
        }
    }];
    [self.task resume];
}

- (void)stopLoading {
    [self.task cancel];
}



@end
