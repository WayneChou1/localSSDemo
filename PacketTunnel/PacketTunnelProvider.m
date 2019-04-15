//
//  PacketTunnelProvider.m
//  PacketTunnel
//
//  Created by 周志伟 on 2019/4/12.
//  Copyright © 2019年 zzw. All rights reserved.
//

#import "PacketTunnelProvider.h"
#import <NetworkExtension/NetworkExtension.h>
#import "SockClient.h"

static NSInteger proxyPort =  8989;
static NSString * const host = @"localhost";

@interface PacketTunnelProvider ()

@property (assign) BOOL started;

@end

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
	// Add code here to start the process of connecting the tunnel.
    
    NEPacketTunnelNetworkSettings *setting = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"8.8.8.8"];
    setting.MTU = @(1500);
    
    NEIPv4Settings *ipv4Setting = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.169.89.1"] subnetMasks:@[@"255.255.255.0"]];
    NEProxySettings *proxySetting = [[NEProxySettings alloc] init];
    proxySetting.HTTPServer = [[NEProxyServer alloc] initWithAddress:@"127.0.0.1" port:proxyPort];
    proxySetting.HTTPEnabled = YES;
    proxySetting.HTTPSServer = [[NEProxyServer alloc] initWithAddress:@"127.0.0.1" port:proxyPort];
    proxySetting.HTTPSEnabled = YES;
    
    setting.proxySettings = proxySetting;
    setting.IPv4Settings = ipv4Setting;
    
    __weak typeof(self) weakSelf = self;
    
    [self setTunnelNetworkSettings:setting completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"set tunnel setting error:%@",error);
            return;
        }
        
        if (!weakSelf.started) {
            SockClient *s = [[SockClient alloc] init];
            s.userName = @"";
            s.password = @"zzw1993";
            [s startWithLocalPort:2222];
            [s connectToHost:host port:proxyPort];
        }
    }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
	// Add code here to start the process of stopping the tunnel.
	completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
	// Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
	// Add code here to get ready to sleep.
	completionHandler();
}

- (void)wake {
	// Add code here to wake up.
}

@end
