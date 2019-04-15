//
//  ProxyProtocol.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ProxyProtocol.h"
#import "CacheStoragePolicy.h"

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
    [self registerClass:self];
}

- (void)startLoading
{
    if (!session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//        configuration.HTTPMaximumConnectionsPerHost = 10;
//        configuration.connectionProxyDictionary =@{(NSString *)kCFStreamPropertySOCKSProxyHost: @"127.0.0.1",(NSString *)kCFStreamPropertySOCKSProxyPort: @(ssLocalPort)};
//        configuration.protocolClasses = @[[ProxyProtocol class]];
        
        NSOperationQueue *q = [[NSOperationQueue alloc] init];
        q.maxConcurrentOperationCount = 1;
        q.name = @"zzw";
        
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    
    __weak typeof(self)weakSelf = self;
//    self.task = [session dataTaskWithRequest:self.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSLog(@"self.request.URL：%@ - %@", self.request.URL, error);
//        if (error) {
//            [weakSelf.client URLProtocol:weakSelf didFailWithError:error];
//        } else {
//            [weakSelf.client URLProtocol:weakSelf didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
//            [weakSelf.client URLProtocol:weakSelf didLoadData:data];
//            [weakSelf.client URLProtocolDidFinishLoading:weakSelf];
//        }
//    }];
    self.task = [session dataTaskWithRequest:self.request];
    [self.task resume];
}

- (void)stopLoading {
    [self.task cancel];
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    
}

//- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
//    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
//}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream * _Nullable))completionHandler {
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask {
    
}

- (void)URLSession:(NSURLSession *)session taskIsWaitingForConnectivity:(NSURLSessionTask *)task {
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    NSURLCacheStoragePolicy cacheStoragePolicy;
    NSInteger               statusCode;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        cacheStoragePolicy = CacheStoragePolicyForRequestAndResponse(self.task.originalRequest, (NSHTTPURLResponse *) response);
        statusCode = [((NSHTTPURLResponse *) response) statusCode];
    } else {
        assert(NO);
        cacheStoragePolicy = NSURLCacheStorageNotAllowed;
        statusCode = 42;
    }
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [[self client] URLProtocol:self didFailWithError:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSMutableURLRequest *    redirectRequest;

    // The new request was copied from our old request, so it has our magic property.  We actually
    // have to remove that so that, when the client starts the new request, we see it.  If we
    // don't do this then we never see the new request and thus don't get a chance to change
    // its caching behaviour.
    //
    // We also cancel our current connection because the client is going to start a new request for
    // us anyway.
    
    // Tell the client about the redirect.
    
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    // Stop our load.  The CFNetwork infrastructure will create a new NSURLProtocol instance to run
    // the load of the redirect.
    
    // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
    // which specificallys traps and ignores the error.
    
    [self.task cancel];
    
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
//{
//    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
//}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler
{
    completionHandler(proposedResponse);
}


@end
