//
//  DynamicEncryptor.h
//  jy_blueSDK
//
//  Created by apple on 2022/4/14.
//  Copyright © 2022 Mr Simetrio. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DynamicEncryptor : NSObject

@property (nonatomic, strong)NSString* confirmKey;
@property (nonatomic, strong) NSString *randomA;
@property (nonatomic, strong) NSString *randomB;
@property (nonatomic, strong) NSData *genKeyData;
@property (nonatomic, strong) NSData *genS1Data;
@property (nonatomic, strong) NSData *genS2Data;
@property (nonatomic, strong) NSData *confirmData;
@property (nonatomic, strong) NSData *deviceKeyData;
@property (nonatomic, strong) NSData *negotiationFrame;
@property (nonatomic, assign) BOOL hasSendMsg;

@property (nonatomic, assign) BOOL beginDynamicCheck;
@property (nonatomic, assign) NSString *dynamicState;

/*
 * 蓝牙连接后开始校验
 */
- (void)connectBleStartCheck;
+ (instancetype)sharedInstance;
- (NSData *) getDecryptData:(NSData *)recvData;

/*
 * 获取动态加密后的数据
 */
- (NSData *)getEncryptData:(NSData *)wifiData;

@end

NS_ASSUME_NONNULL_END
