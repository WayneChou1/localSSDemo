//
//  VPNManager.h
//  localSSDemo
//
//  Created by 周志伟 on 2019/4/13.
//  Copyright © 2019年 zzw. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VPNManager;

typedef enum {
    VPNOff = 0,
    VPNConnecting,
    VPNOn,
    VPNDisconnecting
} VpnStatus;

typedef void(^VPNStatusChangeHandler)(VPNManager *manager,VpnStatus status);


NS_ASSUME_NONNULL_BEGIN

@interface VPNManager : NSObject

+ (instancetype)shareManager:(VPNStatusChangeHandler)handler;

@end

NS_ASSUME_NONNULL_END
