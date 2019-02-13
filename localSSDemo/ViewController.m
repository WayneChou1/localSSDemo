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

static NSString * const host = @"207.246.81.47";
static NSInteger port = 8989;

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
        [self.s startWithLocalPort:9090];
        [self.s connectToHost:host port:port];
    }
}

- (IBAction)nextBtnOnClick:(UIButton *)sender {
    [self.navigationController pushViewController:[WebViewController new] animated:YES];
}
@end
