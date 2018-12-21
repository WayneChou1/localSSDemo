//
//  SockClient.h
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SockClient : NSObject

- (BOOL)startWithLocalPort:(int)localPort;

@end

NS_ASSUME_NONNULL_END
