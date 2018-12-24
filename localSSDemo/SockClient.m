//
//  SockClient.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "SockClient.h"
#import <GCDAsyncSocket.h>

@interface EVPipeline : NSObject
{
@public
//    struct encryption_ctx sendEncryptionContext;
//    struct encryption_ctx recvEncryptionContext;
}

@property (nonatomic, strong) GCDAsyncSocket *localSocket;
@property (nonatomic, strong) GCDAsyncSocket *remoteSocket;
@property (nonatomic, assign) int stage;
@property (nonatomic, strong) NSData *addrData;
@property (nonatomic, strong) NSData *requestData;
@property (nonatomic, strong) NSData *destinationData;    //!< 用于存续将目标地址解析后的数据

- (void)disconnect;

@end

@implementation EVPipeline

- (void)disconnect {
    [self.localSocket disconnectAfterReadingAndWriting];
    [self.remoteSocket disconnectAfterReadingAndWriting];
}

@end

@interface SockClient () <GCDAsyncSocketDelegate>{
    NSMutableArray *_pipelines;      /// 所有连接Socks Server 的Object
}

@property (nonatomic,strong) GCDAsyncSocket *listenServer;
@property (nonatomic,strong) GCDAsyncSocket *remoteSocket;
@property (nonatomic,strong) EVPipeline *socket;

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
    EVPipeline *pipeline = [[EVPipeline alloc] init];
    pipeline.localSocket = newSocket;
    [_pipelines addObject:pipeline];
    [pipeline.localSocket readDataWithTimeout:-1 tag:0];
    self.socket = pipeline;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"tag:%ld,  didReadData:%@",tag,data);
    if (tag == 0) {
        // get request data
        [self.socket.localSocket writeData:[NSData dataWithBytes:"\x05\x00" length:2] withTimeout:-1 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"didWriteDataWithTag:%ld",tag);
}

#pragma mark - getter

- (dispatch_queue_t)listenQueen {
    if (!_listenQueen) {
        _listenQueen = dispatch_queue_create("zzw.localSSDemo", NULL);
    }
    return _listenQueen;
}

@end
