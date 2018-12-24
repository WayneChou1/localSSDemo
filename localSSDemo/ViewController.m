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
        [self.s startWithLocalPort:9090];
    }
}

- (IBAction)nextBtnOnClick:(UIButton *)sender {
    [self.navigationController pushViewController:[WebViewController new] animated:YES];
}
@end
