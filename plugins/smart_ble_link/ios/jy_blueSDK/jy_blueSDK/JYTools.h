//
//  jyTools.h
//  jy_BluetoothSDK
//
//  Created by Mr Simetrio on 2019/6/4.
//  Copyright © 2019 Mr Simetrio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BleDelegate <NSObject>

@required

- (void)BLEDidGetDeviceMac:(NSString *)mac;

- (void)BLEDidDiscoverDeviceWithMAC:(CBPeripheral *)peripheral;

- (void)BLEIsSuccesee:(NSString *)str;

- (void)BLEDidFinishedWithResult:(BOOL)result andPara:(NSMutableArray *)para;

@end

@interface JYTools : NSObject

@property(nonatomic, weak) id <BleDelegate> discoverDelegate;

/** Init Bluetooth */
+ (instancetype)shareInstance;

/** 扫描设备 */
- (void)scanDevice;

/** 停止扫描 */
- (void)stopScan;

/** 连接设备 */
- (void)connectDevice:(CBPeripheral *)peripheral;

/** 断开设备连接 */
- (void)unConnectDevice;

/** 重连设备 */
//- (void)reConnectDevice:(BOOL)isConnect;

/** 检索已连接的外接设备 */
- (NSArray *)retrieveConnectedPeripherals;

- (void) setUserDataAndContinue:(NSString *)userData;

/** WI-FI SSID */
+ (void)setSSID:(NSString *)ssid;

/**IS-Dynamic*/
+ (void)setDynamic:(BOOL)dynamic;

+ (NSString *)getSSID;

/** WI-FI Password */
+ (void)setPassword:(NSString *)password;

+ (NSString *)getPassword;

/** BLE name */
+ (void)setBLEName:(NSString *)bleName;

+ (NSString *)getBleName;

/** UserData */
+ (void)setUserData:(NSString *)userData;

+ (NSString *)getUserData;

/** post */
+ (NSMutableArray *)getPostData;

@end

NS_ASSUME_NONNULL_END
