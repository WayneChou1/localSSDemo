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

@property (nonatomic,copy) NSString *userName;
@property (nonatomic,copy) NSString *password;

- (BOOL)startWithLocalPort:(int)localPort;
- (void)connectToHost:(NSString *)host port:(NSInteger)port;

@end

NS_ASSUME_NONNULL_END

