//
//  VPNManager.m
//  localSSDemo
//
//  Created by 周志伟 on 2019/4/13.
//  Copyright © 2019年 zzw. All rights reserved.
//

#import "VPNManager.h"
#import <NetworkExtension/NetworkExtension.h>

@interface VPNManager ()

@property (assign) BOOL observerDidAdd;
@property (assign) VpnStatus vpnStatus;

@end

@implementation VPNManager

+ (instancetype)shareManager:(VPNStatusChangeHandler)handler {
    static VPNManager *manager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        manager = [[VPNManager alloc] init];
        [manager addVPNStatusObserver:handler];
    });
    
    return manager;
}

- (void)addVPNStatusObserver:(VPNStatusChangeHandler)handler {
    if (!self.observerDidAdd) {
        [self loadProviderManager:^(NETunnelProviderManager *manager) {
            [[NSNotificationCenter defaultCenter] addObserverForName:NEVPNStatusDidChangeNotification object:manager.connection queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                [self updateVPNStatus:manager handler:handler];
            }];
        }];
    }
}

- (void)updateVPNStatus:(NETunnelProviderManager *)manager handler:(VPNStatusChangeHandler)handler {

    switch (manager.connection.status) {
        case NEVPNStatusConnected:
            self.vpnStatus = VPNOn;
            break;
        case NEVPNStatusConnecting:
        case NEVPNStatusReasserting:
            self.vpnStatus = VPNConnecting;
            break;
        case NEVPNStatusDisconnecting:
            self.vpnStatus = VPNDisconnecting;
            break;
        case NEVPNStatusDisconnected:
        case NEVPNStatusInvalid:
            self.vpnStatus = VPNOff;
            break;
        default:
            break;
    }
    
    if (handler) {
        handler(self,self.vpnStatus);
    }
}

- (void)loadProviderManager:(void(^)(NETunnelProviderManager *))block {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (managers.count > 0) {
            block(managers.firstObject);
        }
        block(nil);
    }];
}

@end
