//
//  UDPManage.h
//  jy_ai
//
//  Created by HH.Fang on 2018/8/3.
//  Copyright © 2018年 coolgo.huang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol udpDelegate <NSObject>

@required

- (void)isUDPSuccess:(NSMutableArray *)arr;

- (void)dataIsSuccess:(NSString *)str;

@end

@interface UDPManage : NSObject

@property(nonatomic, weak) id <udpDelegate> UDPDelegate;

+ (instancetype)shareUDPManage;

- (void)broadcast;

@end
