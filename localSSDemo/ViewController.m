//
//  ViewController.m
//  localSSDemo
//
//  Created by 周志伟 on 2018/12/19.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ViewController.h"
#import "SockClient.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)startBtnOnClick:(UIButton *)sender {
    SockClient *s = [[SockClient alloc] init];
    [s startWithLocalPort:9090];
}

@end
