//
//  ProxyProtocol.h
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import <Foundation/Foundation.h>

static int ssLocalPort;

NS_ASSUME_NONNULL_BEGIN

@interface ProxyProtocol : NSURLProtocol

+ (void)setLocalPort:(NSInteger)localPort;

@end

NS_ASSUME_NONNULL_END
