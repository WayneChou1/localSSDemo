//
//  SockClient.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "SockClient.h"
#import <GCDAsyncSocket.h>
#import "3rd/socks5.h"
#include <arpa/inet.h>
#include "3rd/libsodium-ios/include/sodium.h"
#import "NSData+AES256.h"

static int const SOCKS_Consult = 111111;            //!< Consult Tag
static int const SOCKS_AUTH_USERPASS = 222222; // Auth
static int const SOCKS_SERVER_RESPONSE = 333333; // Response
static NSInteger const ADDR_STR_LEN = 512;            //!< url length

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
    NSString *_host;
    NSInteger _port;
}

@property (nonatomic,strong) GCDAsyncSocket *listenServer;
@property (nonatomic,strong) GCDAsyncSocket *remoteSocket;

@property (nonatomic,strong) dispatch_queue_t listenQueen;

@end

@implementation SockClient

#pragma mark - 根据Local/Remote Socket,查找Super Object
/**
 *  根据当前local socket对象查找父对象
 *
 *  @param localSocket localSocket
 *
 *  @return EVPipeline Object
 */
- (EVPipeline *)pipelineOfLocalSocket:(GCDAsyncSocket *)localSocket {
    __block EVPipeline *ret;
    [_pipelines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EVPipeline *pipeline = obj;
        if (pipeline.localSocket == localSocket) {
            ret = pipeline;
        }
    }];
    return ret;
}

/**
 *  根据当前remote socket对象查找父对象
 *
 *  @param remoteSocket remoteSocket
 *
 *  @return EVPipeline Object
 */
- (EVPipeline *)pipelineOfRemoteSocket:(GCDAsyncSocket *)remoteSocket {
    __block EVPipeline *ret;
    [_pipelines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EVPipeline *pipeline = obj;
        if (pipeline.remoteSocket == remoteSocket) {
            ret = pipeline;
        }
    }];
    return ret;
}

- (BOOL)startWithLocalPort:(int)localPort {
    if (!self.listenServer) {
        self.listenServer = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:self.listenQueen];
        
        NSError *error;
        [self.listenServer acceptOnPort:localPort error:&error];
        if (error) {
            NSLog(@"startWithLocalPort Error:%@",error);
            return  NO;
        }
        NSLog(@"开始监听%d端口",localPort);
        _pipelines = @[].mutableCopy;
    }
    return YES;
}

- (void)connectToHost:(NSString *)host port:(NSInteger)port {
    _host = host;
    _port = port;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"Accept Success");
    EVPipeline *pipeline = [[EVPipeline alloc] init];
    pipeline.localSocket = newSocket;
    [_pipelines addObject:pipeline];
    [pipeline.localSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    EVPipeline *pipeline = [self pipelineOfLocalSocket:sock] ?: [self pipelineOfRemoteSocket:sock];
    
    NSString *dataStr = [data description];
    NSLog(@"didReadTag:%ld,  didReadData:%@",tag,dataStr);
    if (tag == 0) {
        // get request data
        [pipeline.localSocket writeData:[NSData dataWithBytes:"\x05\x00" length:2] withTimeout:-1 tag:0];
    }else if (tag == 1) {
        pipeline.requestData = data;
        [self setConsultMethodNoWithPipeline:pipeline];
    }else if (tag == 2) {         // read data from local, send to remote
        /**
         *  存储本地解析后的目标服务器地址信息，等待Socks Server响应成功后
         *  再次将上面信息发送到Socks Server，获取目标服务器详细信息
         */
//        NSLog(@"pipeline.destinationData:%@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
        pipeline.destinationData = data;
        [pipeline.remoteSocket writeData:data withTimeout:-1 tag:4];
        
    }else if (tag == 3) { // read data from remote, send to local
        NSString *key = @"zzw1993";
//        NSData *decryptData = [data AES128OperationWithEncriptionMode:kCCEncrypt key:keyData iv:keyData];
//        NSData *decryptData = [data CFBWithOperation:kCCEncrypt andIv:key andKey:key];
//        NSLog(@"didReadTagDecode:%ld,  didReadData:%@",tag,[decryptData description]);
//        [pipeline.localSocket writeData:decryptData withTimeout:-1 tag:3];
        [pipeline.localSocket writeData:data withTimeout:-1 tag:3];
    }
    else if (tag == SOCKS_Consult) {
        [self socksConsultWithPipeline:pipeline data:data];
    }else if (tag == SOCKS_AUTH_USERPASS) {
        [self socksAuthUserPassWithPipeline:pipeline data:data];
    }else if(tag == SOCKS_SERVER_RESPONSE) {   //
        /**
         *  响应目标服务器
         *
         *  验证成功之后， 发送目标地址到Socks Server
         *
         *  等Socks Server响应并返回data(/0x05/0x00...)后， 即可转发
         */
        uint8_t *bytes = (uint8_t*)[data bytes];
        uint8_t version = bytes[0];
        uint8_t flag = bytes[1];
        if(version == 5) {
            if(flag == 0) {
#ifdef DEBUG
                NSLog(@"fake reply Successful, request destination data");
#endif
                [self socksFakeReply:pipeline];
            }
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"didWriteDataWithTag:%ld",tag);
    EVPipeline *pipeline = [self pipelineOfLocalSocket:sock] ?: [self pipelineOfRemoteSocket:sock];
    
    if (tag == 0) {
        [pipeline.localSocket readDataWithTimeout:-1 tag:1];
    }
    if (tag == SOCKS_Consult) {
        
    }else if (tag == 2){
//        [pipeline.remoteSocket readDataWithTimeout:-1 tag:3];
//        [pipeline.localSocket readDataWithTimeout:-1 tag:2];
    }else if (tag == 3) {
        // write data to local
//        [pipeline.remoteSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:3];
//        [pipeline.localSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:2];
        [pipeline.remoteSocket readDataWithTimeout:-1 tag:3];
        [pipeline.localSocket readDataWithTimeout:-1 tag:2];
    }else if (tag == 4) {
        // write data to remote
//        [pipeline.remoteSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:3];
//        [pipeline.localSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:2];
        [pipeline.remoteSocket readDataWithTimeout:-1 tag:3];
        [pipeline.localSocket readDataWithTimeout:-1 tag:2];
    }else if(tag == SOCKS_SERVER_RESPONSE) {
        [pipeline.remoteSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:4096 tag:SOCKS_SERVER_RESPONSE];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"didConnect:%@",sock);
    
    EVPipeline *pipeline = [self pipelineOfRemoteSocket:sock];
    [pipeline.remoteSocket writeData:pipeline.addrData withTimeout:-1 tag:2];
//    [sock startTLS:nil];
    [self socksFakeReply:pipeline];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"disConnectError:%@",err.localizedDescription);
}

#pragma mark - 设置Proxy Server协商方式
#pragma mark -- 无需协商
- (void)setConsultMethodNoWithPipeline:(EVPipeline *)pipeline {
    char addr_to_send[ADDR_STR_LEN];
    int addr_len = 0;
    addr_len = [self transformDataToProxyServer:pipeline addr:addr_to_send addr_len:addr_len];
    GCDAsyncSocket *remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.listenQueen];
    pipeline.remoteSocket = remoteSocket;
    [remoteSocket connectToHost:_host onPort:_port error:nil];
    
    NSString *key = @"zzw1993";
    NSLog(@"addr_to_send3：%s",addr_to_send);
    NSData *addrData = [NSData dataWithBytes:addr_to_send length:addr_len];
//    pipeline.addrData = [addrData CFBWithOperation:kCCEncrypt andIv:key andKey:key];
//    pipeline.addrData = [addrData AES256OperationWithEncriptionMode:kCCEncrypt key:keyData iv:keyData];
    pipeline.addrData = addrData;
    NSLog(@"addrData:%@",[pipeline.addrData description]);
}

//- (NSData *)CFBWithOperation:(CCOperation)operation andIv:(NSString *)ivString andKey:(NSString *)keyString andInput:(NSData *)inputData{
//
//    const char *iv = [[ivString dataUsingEncoding: NSUTF8StringEncoding] bytes];
//    const char *key = [[keyString dataUsingEncoding: NSUTF8StringEncoding] bytes];
//
//    CCCryptorRef cryptor;
//    CCCryptorCreateWithMode(operation, kCCModeCFB, kCCAlgorithmAES, ccNoPadding, iv, key, [keyString length], NULL, 0, 0, 0, &cryptor);
//
//    NSUInteger inputLength = inputData.length;
//    char *outData = malloc(inputLength);
//    memset(outData, 0, inputLength);
//    size_t outLength = 0;
//    CCCryptorUpdate(cryptor, inputData.bytes, inputLength, outData, inputLength, &outLength);
//    NSData *data = [NSData dataWithBytes: outData length: outLength];
//    CCCryptorRelease(cryptor);
//    free(outData);
//    return data;
//}

#pragma mark -- USERNAME/PASSWORD 协商
//- (void)setConsultMethodUSRPSDWith:(EVPipeline *)pipeline data:(NSData *)data{
//    // store request data
//    self.readSocket.requestData = data;
//    if(!pipeline.remoteSocket) {
//        NSError *connectErr = nil;
//        self.readSocket.remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.listenQueen];
//        [self.readSocket.remoteSocket connectToHost:_host onPort:_port error:&connectErr];
//        if (connectErr) {
//            NSLog(@"connect error:%@",connectErr.localizedDescription);
//        }
//        NSLog(@"writeSockrt.remoteSocket:%@",self.readSocket.remoteSocket);
//    }
//}

#pragma mark - 协商
#pragma mark -- 开始协商
/**
 *  Sends the SOCKS5 open/handshake/authentication data, and starts reading the response.
 *  We attempt to gain anonymous access (no authentication).
 *
 *      +-----+-----------+---------+
 * NAME | VER | NMETHODS  | METHODS |
 *      +-----+-----------+---------+
 * SIZE |  1  |    1      | 1 - 255 |
 *      +-----+-----------+---------+
 *
 *  Note: Size is in bytes
 *
 *  Version    = 5 (for SOCKS5)
 *  NumMethods = 1
 *  Method     = 0 (No authentication, anonymous access)
 *  @param rmSocket remote Socket
 */
- (void)socksOpenWithSocket:(GCDAsyncSocket *)rmSocket
{
    NSUInteger byteBufferLength = 3;
    uint8_t *byteBuffer = malloc(byteBufferLength * sizeof(uint8_t));
    
    uint8_t version = 5; /// VER
    byteBuffer[0] = version;
    
    uint8_t numMethods = 1; /// NMETHODS
    byteBuffer[1] = numMethods;
    
    uint8_t method = 0; /// 0 == no auth
    //method = 2; // username/password
    byteBuffer[2] = method;
    
    NSData *data = [NSData dataWithBytesNoCopy:byteBuffer length:byteBufferLength freeWhenDone:YES];
    [rmSocket writeData:data withTimeout:-1 tag:SOCKS_Consult];
    [self socksReadConsultDataWithSocket:rmSocket];
}

/**
 *  读取与Proxy Server 协商返回的结果
 *
 *          +-----+--------+
 *    NAME  | VER | METHOD |
 *          +-----+--------+
 *    SIZE  |  1  |   1    |
 *          +-----+--------+
 *
 *  Note: Size is in bytes
 *
 *  Version = 5 (for SOCKS5)
 *  Method  = 0 (No authentication, anonymous access)
 *
 *  @param socket remote Socket
 */
- (void)socksReadConsultDataWithSocket:(GCDAsyncSocket *)socket {
    [socket readDataToLength:2 withTimeout:-1 tag:SOCKS_Consult];
}

- (void)socksConsultWithPipeline:(EVPipeline *)pipeline data:(NSData *)data {
    // See socksOpen method for socks reply format
    uint8_t *bytes = (uint8_t*)[data bytes];
    uint8_t version = bytes[0];
    uint8_t method = bytes[1];
    if(version == 5) {
        if(method == 0) {
            // No Auth
            NSLog(@"无需协商");
        }
        else if(method == 2) {
            // Username/Password Validate
            [self socksUserPassAuthWithSocket:pipeline.remoteSocket usr:self.userName psd:self.password];
        }
        else {
            // unsupported auth method
            [pipeline.remoteSocket disconnect];
            NSLog(@"socks服务器协商方式不支持，请检查支持的协商方式");
        }
    }
}

#pragma mark - 登录
#pragma mark -- 封装USERNAME/PASSWORD 为Package
/**
 *  封装username/password为package
 *        +-----+-------------+----------+-------------+------------
 *   NAME | VER | USERNAMELen | USERNAME | PASSWORDLEN |  PASSWORD  |
 *         +-----+------------+----------+-------------+------------
 *   SIZE |  1   |     1      |  1 - 255 |      1      |  1 - 255   |
 *         +-----+------------+----------+-------------+------------
 *
 *  @param rmSocket remote socket
 */
- (void)socksUserPassAuthWithSocket:(GCDAsyncSocket *)rmSocket usr:(NSString *)username psd:(NSString *)password {
    NSData *usernameData = [username dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t usernameLength = (uint8_t)username.length;
    uint8_t passwordLength = (uint8_t)password.length;
    
    NSMutableData *authData = [NSMutableData dataWithCapacity:1+1+usernameLength + 1 + passwordLength];
    uint8_t version[1] = {0x01};
    [authData appendBytes:version length:1];
    [authData appendBytes:&usernameLength length:1];
    [authData appendBytes:usernameData.bytes length:usernameLength];
    [authData appendBytes:&passwordLength length:1];
    [authData appendBytes:passwordData.bytes length:passwordLength];
    
    // 与Server 验证用户名和密码    ^^^^^^^这里需要加密
    [rmSocket writeData:authData withTimeout:-1 tag:SOCKS_AUTH_USERPASS];
    [rmSocket readDataToLength:2 withTimeout:-1 tag:SOCKS_AUTH_USERPASS];
}

#pragma mark -- USERNAME/PASSWORD 登录验证结果
/**
 *  Server response for username/password authentication:
 *  field 1: version, 1 byte
 *  filed 2: status code, 1 byte
 *  0x00 = success
 *  any other value = failure, connection must be closed
 */
- (void)socksAuthUserPassWithPipeline:(EVPipeline *)pipeline data:(NSData *)data {
    if(data.length == 2) {
        uint8_t *bytes = (uint8_t *)[data bytes];
        uint8_t status = bytes[1];
        if(status ==0x00) {
            // 验证成功， 开始访问数据
            // set delegate
            
            char addr_to_send[ADDR_STR_LEN];
            int addr_len = 0;
            
            addr_len = [self transformDataToProxyServer:pipeline addr:addr_to_send addr_len:addr_len];
            
            [pipeline.remoteSocket writeData:pipeline.requestData withTimeout:-1 tag:SOCKS_SERVER_RESPONSE];
            pipeline.addrData = [NSData dataWithBytes:addr_to_send length:addr_len];
        }
        else {
            [pipeline.remoteSocket disconnect];
            return;
        }
    }
    else {
        NSLog(@"服务器返回数据长度异常:%@",data);
        // 返回数据超过2个字节长度
        [pipeline.remoteSocket disconnect];
        return;
    }
}

#pragma mark - 请求转发/fade reply
/**
 *  根据destination host & prot 获取的data，转发Proxy Server
 */
- (int)transformDataToProxyServer:(EVPipeline *)pipeline addr:(char [ADDR_STR_LEN])addr_to_send addr_len:(int)addr_len {
    
    NSMutableString *string = [[NSMutableString alloc] init];
    unsigned char *dataBytes = (unsigned char*)pipeline.requestData.bytes;
    for (NSInteger i = 0; i < 4; i++) {
        NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
        if ([hexStr length] == 2) {
            [string appendString:hexStr];
        } else {
            [string appendFormat:@"0%@", hexStr];
        }
    }
    NSLog(@"requestData.bytes:%@",string);
    
    // transform data
    struct socks5_request *request = (struct socks5_request *)pipeline.requestData.bytes;
    if (request->cmd != SOCKS_CMD_CONNECT) {
        struct socks5_response response;
        response.ver = SOCKS_VERSION;
        response.rep = SOCKS_CMD_NOT_SUPPORTED;
        response.rsv = 0;
        response.atyp = SOCKS_IPV4;
        char *send_buf = (char *)&response;
        [pipeline.localSocket writeData:[NSData dataWithBytes:send_buf length:4] withTimeout:-1 tag:1];
        [pipeline disconnect];
        return -1;
    }
    
    addr_to_send[addr_len++] = request->atyp;
    char addr_str[ADDR_STR_LEN];
    // get remote addr and port
    if (request->atyp == SOCKS_IPV4) {
        // IP V4
        size_t in_addr_len = sizeof(struct in_addr);
        memcpy(addr_to_send + addr_len, pipeline.requestData.bytes + 4, in_addr_len + 2);
        
        NSLog(@"addr_to_send：%s",addr_to_send);
        
        addr_len += in_addr_len + 2;
        
        // now get it back and print it
        inet_ntop(AF_INET, pipeline.requestData.bytes + 4, addr_str, ADDR_STR_LEN);
    } else if (request->atyp == SOCKS_DOMAIN) {
        // Domain name
        
        NSLog(@"addr_to_send1：%s",addr_to_send);
        
        unsigned char name_len = *(unsigned char *)(pipeline.requestData.bytes + 4);
        addr_to_send[addr_len++] = name_len;
        memcpy(addr_to_send + addr_len, pipeline.requestData.bytes + 4 + 1, name_len);
        memcpy(addr_str, pipeline.requestData.bytes + 4 + 1, name_len);
        addr_str[name_len] = '\0';
        addr_len += name_len;
        
        NSLog(@"addr_to_send2：%s",addr_to_send);
        
        // get port
        unsigned char v1 = *(unsigned char *)(pipeline.requestData.bytes + 4 + 1 + name_len);
        unsigned char v2 = *(unsigned char *)(pipeline.requestData.bytes + 4 + 1 + name_len + 1);
        addr_to_send[addr_len++] = v1;
        addr_to_send[addr_len++] = v2;
        
        NSLog(@"name_len:%x",name_len);
        NSLog(@"addr_to_send3：%s",addr_to_send);
//        NSLog(@"addr_len:%d",addr_len);
    } else {
        [pipeline disconnect];
        return -1;
    }
    return addr_len;
}

/**
 *  local socket 回调
 *
 *  @param pipeline pipeline
 */
- (void)socksFakeReply:(EVPipeline *)pipeline {
    // Fake reply
    struct socks5_response response;
    response.ver = SOCKS_VERSION;
    response.rep = 0;
    response.rsv = 0;
    response.atyp = SOCKS_IPV4;
    
    struct in_addr sin_addr;
    inet_aton("0.0.0.0", &sin_addr);
    
    int reply_size = 4 + sizeof(struct in_addr) + sizeof(unsigned short);
    char *replayBytes = (char *)malloc(reply_size);
    
    memcpy(replayBytes, &response, 4);
    memcpy(replayBytes + 4, &sin_addr, sizeof(struct in_addr));
    *((unsigned short *)(replayBytes + 4 + sizeof(struct in_addr))) = (unsigned short) htons(pipeline.localSocket.connectedPort);
    
    NSData *reponseData = [NSData dataWithBytes:replayBytes length:reply_size];
    NSLog(@"reponseData:%@",reponseData);
    
    [pipeline.localSocket writeData:reponseData withTimeout:-1 tag:3];
    free(replayBytes);
}

#pragma mark - getter

- (dispatch_queue_t)listenQueen {
    if (!_listenQueen) {
        _listenQueen = dispatch_queue_create("zzw.localSSDemo", NULL);
    }
    return _listenQueen;
}

@end
