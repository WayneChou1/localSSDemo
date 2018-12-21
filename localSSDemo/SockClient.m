//
//  SockClient.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "SockClient.h"
#import <GCDAsyncSocket.h>

@interface SockClient () <GCDAsyncSocketDelegate>

@property (nonatomic,strong) GCDAsyncSocket *listenServer;
@property (nonatomic,strong) dispatch_queue_t listenQueen;

@end

@implementation SockClient

- (BOOL)startWithLocalPort:(int)localPort {
    if (!self.listenServer) {
        self.listenServer = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:self.listenQueen];
        
        NSError *error;
        [self.listenServer acceptOnPort:localPort error:&error];
        if (error) {
            NSLog(@"startWithLocalPort Error:%@",error);
            return  NO;
        }
        
    }
    return YES;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"Accept Success");
    [self.listenServer readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"tag:%ld,  data:%@",tag,data);
}

#pragma mark - getter

- (dispatch_queue_t)listenQueen {
    if (!_listenQueen) {
        _listenQueen = dispatch_queue_create("zzw.localSSDemo", NULL);
    }
    return _listenQueen;
}

@end
