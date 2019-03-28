//
//  NSData+AES256.h
//  localSSDemo
//
//  Created by zhouzhiwei on 2019/3/28.
//  Copyright © 2019 zzw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@interface NSData (AES256)

//- (NSData *)aes256_encrypt:(NSString*)key iv:(NSString *)iv;
//- (NSData *)CFBWithOperation:(CCOperation)operation andIv:(NSString *)ivString andKey:(NSString *)keyString;
//- (NSData *)AES128OperationWithEncriptionMode:(CCOperation)operation key:(NSData *)key iv:(NSData *)iv;
- (NSData *)CFBWithOperation:(CCOperation)operation andIv:(NSString *)ivString andKey:(NSString *)keyString;

@end

