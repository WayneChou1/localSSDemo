//
//  NSData+AES256.m
//  localSSDemo
//
//  Created by zhouzhiwei on 2019/3/28.
//  Copyright © 2019 zzw. All rights reserved.
//

#import "NSData+AES256.h"

@implementation NSData (AES256)

//- (NSData *)aes256_encrypt:(NSString*)key iv:(NSString *)iv {
//
//    //AES的密钥长度256字节
//    char keyPtr[kCCKeySizeAES256+1];
//    bzero(keyPtr, sizeof(keyPtr));
//    BOOL tansform = NO;
//    tansform = [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
//    if (!tansform) {
//        return nil;
//    }
//
//    char ivPtr[kCCKeySizeAES256+1];
//    memset(ivPtr, 0, sizeof(ivPtr));
//    tansform = [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
//    if (!tansform) {
//        return nil;
//    }
//
//    //密文的长度
//    NSUInteger dataLength = [self length];
//    //密文长度+补位长度
//    size_t bufferSize = dataLength + kCCKeySizeAES256;
//    //为加密结果开辟空间
//    void *buffer = malloc(bufferSize);
//    size_t numBytesEncrypted = 0;
//
//    /* kCCDecrypt:加密/解密
//          * kCCAlgorithmAES128:加密方式
//          * kCCOptionPKCS7Padding | kCCOptionECBMode:工作模式
//          * keyPtr:UTF-8格式的key
//          * kCCKeySizeAES256：按32位长度解密
//          * iv:私钥
//          * [self bayes]:密文
//          * ...
//     */
//    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
//                                          kCCAlgorithmAES128,
//                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
//                                          keyPtr,
//                                          kCCKeySizeAES256,
//                                          ivPtr,
//                                          [self bytes],
//                                          dataLength,
//                                          buffer,
//                                          bufferSize,
//                                          &numBytesEncrypted);
//    if (cryptStatus == kCCSuccess) {
//        NSData *encryptData = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
//        free(buffer);
//        return encryptData;
//    }
//    free(buffer);
//    return nil;
//}

- (NSData *)CFBWithOperation:(CCOperation)operation andIv:(NSString *)ivString andKey:(NSString *)keyString {
    
    //AES的密钥长度256字节
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    BOOL tansform = NO;
    tansform = [keyString getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    if (!tansform) {
        return nil;
    }
    
    char ivPtr[kCCKeySizeAES256+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    tansform = [ivString getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    if (!tansform) {
        return nil;
    }
    
//    const char *iv = [[ivString dataUsingEncoding: NSUTF8StringEncoding] bytes];
//    const char *key = [[keyString dataUsingEncoding: NSUTF8StringEncoding] bytes];
    
    CCCryptorRef cryptor;
    CCCryptorStatus status = CCCryptorCreateWithMode(operation, kCCModeCFB, kCCAlgorithmAES, ccNoPadding, ivPtr, keyPtr, kCCKeySizeAES256, NULL, 0, 0, 0, &cryptor);
    if (status != kCCSuccess) {
        NSLog(@"加密失败，code=%d",status);
    }
    
    NSUInteger inputLength = self.length;
    char *outData = malloc(inputLength);
    memset(outData, 0, inputLength);
    size_t outLength = 0;
    CCCryptorUpdate(cryptor, self.bytes, inputLength, outData, inputLength, &outLength);
    NSData *data = [NSData dataWithBytes: outData length: outLength];
    NSData *oData = [data base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    CCCryptorRelease(cryptor);
    free(outData);
    return oData;
}

@end
