//
//  URLSchemeHandler.h
//  localSSDemo
//
//  Created by zhouzhiwei on 2018/12/21.
//  Copyright © 2018 zzw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

static int ssLocalPort;

NS_ASSUME_NONNULL_BEGIN

@interface URLSchemeHandler : NSObject <WKURLSchemeHandler>

+ (void)setLocalPort:(int)localPort;

@end

NS_ASSUME_NONNULL_END
