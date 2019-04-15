//
//  AppDelegate.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "AppDelegate.h"
#import "URLSchemeHandler.h"
#import "ProxyProtocol.h"
#import "CustomHTTPProtocol.h"
#import "CredentialsManager.h"
#import <SOCKSProxy.h>
#import <GCDAsyncProxySocket.h>

@interface AppDelegate ()

@property (nonatomic, strong, readwrite) CredentialsManager *   credentialsManager;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    [URLSchemeHandler setLocalPort:9191];
//    [ProxyProtocol setLocalPort:2222];
    
//    SOCKSProxy *proxy = [[SOCKSProxy alloc] init];
//    [proxy startProxyOnPort:9050];
    
//    GCDAsyncProxySocket *socket = [[GCDAsyncProxySocket alloc] init];
//    [socket setProxyHost:@"127.0.0.1" port:2222 version:GCDAsyncSocketSOCKSVersion5];
//    [socket connectToHost:@"127.0.0.1" onPort:8989 error:nil];
    
    self.credentialsManager = [[CredentialsManager alloc] init];
    
    [CustomHTTPProtocol setDelegate:self];
    if (YES) {
        [CustomHTTPProtocol start];
    }
    return YES;
}


- (void)logWithPrefix:(NSString *)prefix format:(NSString *)format arguments:(va_list)arguments
{
    assert(prefix != nil);
    assert(format != nil);
    
//    if (sAppDelegateLoggingEnabled) {
//        NSTimeInterval  now;
//        ThreadInfo *    threadInfo;
//        NSString *      str;
//        char            elapsedStr[16];
//
//        now = [NSDate timeIntervalSinceReferenceDate];
//
//        threadInfo = [self threadInfoForCurrentThread];
//
//        str = [[NSString alloc] initWithFormat:format arguments:arguments];
//        assert(str != nil);
//
//        snprintf(elapsedStr, sizeof(elapsedStr), "+%.1f", (now - sAppStartTime));
//
//        fprintf(stderr, "%3zu %s %s%s\n", (size_t) threadInfo.number, elapsedStr, [prefix UTF8String], [str UTF8String]);
//    }
}


- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol logWithFormat:(NSString *)format arguments:(va_list)arguments
{
    NSString *  prefix;
    
    // protocol may be nil
    assert(format != nil);
    
    if (protocol == nil) {
        prefix = @"protocol ";
    } else {
        prefix = [NSString stringWithFormat:@"protocol %p ", protocol];
    }
    [self logWithPrefix:prefix format:format arguments:arguments];
}


/*! Called by the test subsystem (see below) to log various bits of information.
 *  Will be called on the main thread.
 *  \param format A standard NSString-style format string; will not be nil.
 */

- (void)testLogWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2)
{
    va_list     arguments;
    
    assert(format != nil);
    
    va_start(arguments, format);
    [self logWithPrefix:@"test " format:format arguments:arguments];
    va_end(arguments);
}

- (BOOL)customHTTPProtocol:(CustomHTTPProtocol *)protocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    assert(protocol != nil);
#pragma unused(protocol)
    assert(protectionSpace != nil);
    
    // We accept any server trust authentication challenges.
    
    return [[protectionSpace authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust];
}

- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    OSStatus            err;
    NSURLCredential *   credential;
    SecTrustRef         trust;
    SecTrustResultType  trustResult;
    
    // Given our implementation of -customHTTPProtocol:canAuthenticateAgainstProtectionSpace:, this method
    // is only called to handle server trust authentication challenges.  It evaluates the trust based on
    // both the global set of trusted anchors and the list of trusted anchors returned by the CredentialsManager.
    
    assert(protocol != nil);
    assert(challenge != nil);
    assert([[[challenge protectionSpace] authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust]);
    assert([NSThread isMainThread]);
    
    credential = nil;
    
    // Extract the SecTrust object from the challenge, apply our trusted anchors to that
    // object, and then evaluate the trust.  If it's OK, create a credential and use
    // that to resolve the authentication challenge.  If anything goes wrong, resolve
    // the challenge with nil, which continues without a credential, which causes the
    // connection to fail.
    
    trust = [[challenge protectionSpace] serverTrust];
    if (trust == NULL) {
        assert(NO);
    } else {
        err = SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef) self.credentialsManager.trustedAnchors);
        if (err != noErr) {
            assert(NO);
        } else {
            err = SecTrustSetAnchorCertificatesOnly(trust, false);
            if (err != noErr) {
                assert(NO);
            } else {
                err = SecTrustEvaluate(trust, &trustResult);
                if (err != noErr) {
                    assert(NO);
                } else {
                    if ( (trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified) ) {
                        credential = [NSURLCredential credentialForTrust:trust];
                        assert(credential != nil);
                    }
                }
            }
        }
    }
    
    [protocol resolveAuthenticationChallenge:challenge withCredential:credential];
}

// We don't need to implement -customHTTPProtocol:didCancelAuthenticationChallenge: because we always resolve
// the challenge synchronously within -customHTTPProtocol:didReceiveAuthenticationChallenge:.

#pragma mark Test Button

/*! Called when the user taps of the (optional) Test button in the nav bar.  This kicks off a various
 *  tests, selectable at compile time by changing the if expressions.
 *  \param sender The object that sent this action.
 */

- (void)testAction:(id)sender
{
#pragma unused(sender)
    if (NO) {
        [self testNSURLConnection];
    }
    if (YES) {
        [self testNSURLSession];
    }
}

#pragma mark NSURLSession test

/*! This routine kicks off a vanilla NSURLSession task, as opposed to the UIWebView test shown by the
 *  main app.  This is useful because UIWebView uses NSURLConnection (actually, the private CFNetwork
 *  API that underlies NSURLConnection, CFURLConnection) in a unique way, so it's important to test
 *  your code with both UIWebView and NSURLSession.
 */

- (void)testNSURLSession
{
    [self testLogWithFormat:@"start (NSURLSession)"];
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://www.apple.com/"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
#pragma unused(data)
        if (error != nil) {
            [self testLogWithFormat:@"error:%@ / %d", [error domain], (int) [error code]];
        } else {
            [self testLogWithFormat:@"success:%zd / %@", (ssize_t) [(NSHTTPURLResponse *) response statusCode], [response URL]];
        }
    }] resume];
}

#pragma mark NSURLConnection test

/*! This routine kicks off a vanilla NSURLConnection, as opposed to the UIWebView test shown by the
 *  main app.  This is useful because UIWebView uses NSURLConnection (actually, the private CFNetwork
 *  API that underlies NSURLConnection, CFURLConnection) in a unique way, so it's important to test
 *  your code with both UIWebView and NSURLConnection.
 */

- (void)testNSURLConnection
{
    [self testLogWithFormat:@"start (NSURLConnection)"];
    (void) [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.apple.com/"]] delegate:self];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
#pragma unused(connection)
    [self testLogWithFormat:@"willSendRequest:%@ redirectResponse:%@", [request URL], [response URL]];
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused(connection)
#pragma unused(response)
    [self testLogWithFormat:@"didReceiveResponse:%zd / %@", (ssize_t) [(NSHTTPURLResponse *) response statusCode], [response URL]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused(connection)
#pragma unused(data)
    [self testLogWithFormat:@"didReceiveData:%zu", (size_t) [data length]];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
#pragma unused(connection)
    [self testLogWithFormat:@"willCacheResponse:%@", [[cachedResponse response] URL]];
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused(connection)
    [self testLogWithFormat:@"connectionDidFinishLoading"];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused(connection)
#pragma unused(error)
    [self testLogWithFormat:@"didFailWithError:%@ / %d", [error domain], (int) [error code]];
}


@end
