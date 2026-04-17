//
//  UDPManage.m
//  jy_ai
//
//  Created by HH.Fang on 2018/8/3.
//  Copyright © 2018年 coolgo.huang. All rights reserved.
//

#import "UDPManage.h"
#import "GCDAsyncUdpSocket.h"

#define udpPort 49999

@interface UDPManage () <GCDAsyncUdpSocketDelegate>
{
    int mCode;
    int number;
}
@property (strong, nonatomic)GCDAsyncUdpSocket * udpSocket;
@end

static UDPManage *myUDPManage = nil;

@implementation UDPManage

+ (instancetype)shareUDPManage {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        myUDPManage = [[UDPManage alloc] init];
        [myUDPManage createClientUdpSocket];
    });
    return myUDPManage;
}

- (void)createClientUdpSocket {
    //创建udp socket
    dispatch_queue_t queue =  dispatch_queue_create("jy.udp", NULL);
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:queue];
    
    //banding一个端口(可选),如果不绑定端口,那么就会随机产生一个随机的电脑唯一的端口
    NSError * error = nil;
    [self.udpSocket bindToPort:udpPort error:&error];
    
    //启用广播
    [self.udpSocket enableBroadcast:YES error:&error];
    
    if (error) {//监听错误打印错误信息
        NSLog(@"error:%@",error);
    } else {//监听成功则开始接收信息
        [self.udpSocket beginReceiving:&error];
    }
}


//广播
- (void)broadcast {
    mCode = -1;
    NSString *str = @"smartlinkfind";
    number = 0;
    
    NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding];
    
    //此处如果写成固定的IP就是对特定的server监测
    NSString *host = @"255.255.255.255";
    
    //发送数据（tag: 消息标记）
    [self.udpSocket sendData:data toHost:host port:48899 withTimeout:-1 tag:100];
}

# pragma mark GCDAsyncUdpSocketDelegate
//发送数据成功
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    if (tag == 100) {
//        NSLog(@"标记为100的数据发送完成了");
        mCode = 0;
        if ([self.UDPDelegate respondsToSelector:@selector(dataIsSuccess:)]) {
            [self.UDPDelegate dataIsSuccess:@"数据发送成功"];
        }
    }
}

//发送数据失败
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"标记为%ld的数据发送失败，失败原因：%@",tag, error);
    mCode = 1;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    NSLog(@"失败");
}

//接收到数据
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    number++;
    NSString *ip = [GCDAsyncUdpSocket hostFromAddress:address];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *strIP = @"";
    
    if ([ip rangeOfString:@"ff"].location == NSNotFound) {
        strIP = [NSString stringWithFormat:@"%@",ip];
    } else {
        NSString *replacedStr = [ip stringByReplacingOccurrencesOfString:@":" withString:@""];
        strIP = [replacedStr stringByReplacingOccurrencesOfString:@"f" withString:@""];
    }
    
    NSString *strMAC = [str stringByReplacingOccurrencesOfString:@"smart_config " withString:@""];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:strIP];
    [arr addObject:strMAC];
    
    if (number==1) {
        if ([self.UDPDelegate respondsToSelector:@selector(isUDPSuccess:)]) {
            [self.UDPDelegate isUDPSuccess:arr];
        }
    }
    
}


@end
