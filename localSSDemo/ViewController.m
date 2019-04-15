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
#import "VPNManager.h"
#import "Core Code/CustomHTTPProtocol.h"
#import <AFHTTPSessionManager.h>
#import <NetworkExtension/NetworkExtension.h>

//static NSString * const host = @"140.82.29.149";
//static NSString * const host = @"10.1.28.73";
static NSString * const host = @"localhost";
static NSInteger port = 8989;

@interface ViewController ()

@property (nonatomic,strong) SockClient *s;
@property (nonatomic,strong) NETunnelProviderManager *tunnelManager;
@property (weak, nonatomic) IBOutlet UISwitch *vpnSwitch;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [VPNManager shareManager:^(VPNManager *manager, VpnStatus status) {
        if (status == VPNOn) {
            self.vpnSwitch.on = YES;
        }else{
            self.vpnSwitch.on = NO;
        }
    }];
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
    [self.navigationController pushViewController:[WebViewController new] animated:YES];
    
//    NSString *path = @"http://v.juhe.cn/movie/index?key=818da00819c17b1df5a9a8f393a4ff9f&title=%E9%92%A2%E9%93%81%E4%BE%A03";
//
//    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    configuration.protocolClasses = @[[CustomHTTPProtocol class]];
//
//    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
//
////    NSMutableArray *protocols = [NSMutableArray arrayWithArray:manager.session.configuration.protocolClasses];
////    [protocols insertObject:[ProxyProtocol class] atIndex:0];
////    manager.session.configuration.protocolClasses = [protocols copy];
//
//    //申明返回的结果是json类型
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//
//    [manager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSLog(@"responseObject:%@",responseObject);
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"error:%@",error);
//    }];
}


- (void)loadVPN {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error == nil) {
            if (managers.count > 0) {
                self.tunnelManager = managers.firstObject;
                if (managers.count > 1) {
                    [managers enumerateObjectsUsingBlock:^(NETunnelProviderManager * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [obj removeFromPreferencesWithCompletionHandler:nil];
                    }];
                }
            }
            
            if (!self.tunnelManager) {
                [self createVPN];
                [self saveVPN];
            }
        }else{
            NSLog(@"load fail:%@",error);
        }
    }];
}


- (void)createVPN {
    self.tunnelManager = [[NETunnelProviderManager alloc] init];
    self.tunnelManager.enabled = YES;
    self.tunnelManager.localizedDescription = @"localSSDemo";
}

- (void)saveVPN {
    [self.tunnelManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (!error) {
            [self.tunnelManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"save success");
                }else{
                    NSLog(@"save error");
                }
            }];
        }else{
            NSLog(@"saveToPreferences:%@",error);
        }
    }];
}

- (void)stopVPN {
    [self.tunnelManager.connection stopVPNTunnel];
}


#pragma mark - switchOnClick

- (IBAction)switchOnClick:(UISwitch *)sender {
    if (sender.isOn) {
        [self loadVPN];
    }else{
        [self stopVPN];
    }
}


@end
