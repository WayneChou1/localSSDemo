//
//  ViewController.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import "SockClient.h"
#import "ProxyProtocol.h"
#import <AFHTTPSessionManager.h>

//static NSString * const host = @"140.82.29.149";
static NSString * const host = @"10.1.28.73";
static NSInteger port = 8989;

//static NSString * const host = @"180.97.33.108";
//static NSInteger port = 443;

@interface ViewController ()

@property (nonatomic,strong) SockClient *s;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)startBtnOnClick:(UIButton *)sender {
    if (!self.s) {
        self.s = [[SockClient alloc] init];
        self.s.userName = @"";
        self.s.password = @"zzw1993";
        [self.s startWithLocalPort:2222];
        [self.s connectToHost:host port:port];
    }
}

- (IBAction)nextBtnOnClick:(UIButton *)sender {
//    [self.navigationController pushViewController:[WebViewController new] animated:YES];
    
    NSString *path = @"http://v.juhe.cn/movie/index?key=818da00819c17b1df5a9a8f393a4ff9f&title=%E9%92%A2%E9%93%81%E4%BE%A03";
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.protocolClasses = @[[ProxyProtocol class]];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    
//    NSMutableArray *protocols = [NSMutableArray arrayWithArray:manager.session.configuration.protocolClasses];
//    [protocols insertObject:[ProxyProtocol class] atIndex:0];
//    manager.session.configuration.protocolClasses = [protocols copy];
    
    //申明返回的结果是json类型
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"responseObject:%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error:%@",error);
    }];
}
@end
