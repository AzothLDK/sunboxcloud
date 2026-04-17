//
//  jyTools.m
//  jy_BluetoothSDK
//
//  Created by Mr Simetrio on 2019/6/4.
//  Copyright © 2019 Mr Simetrio. All rights reserved.
//

#import "JYTools.h"
#import "CRC.h"
#import "TeaEncryptor.h"
#import "UDPManage.h"
#import "DynamicEncryptor.h"
#import "cocoaSecurity/CocoaSecurity.h"

@interface JYTools () <CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager  * Manager;
@property (nonatomic, strong) CBPeripheral      * currentPer;
@property (nonatomic, strong) CBCharacteristic  * writeCharacteristic;
@property (nonatomic, strong) CBCharacteristic  * notifyCharacteristic;
@property (nonatomic, strong) NSMutableArray    * bleMArray;
@property (nonatomic, strong) NSMutableArray    * frames;
@property (nonatomic, strong) NSString          * ssidStr;
@property (nonatomic, strong) NSString          * passwordStr;
@property (nonatomic, strong) NSString          * bleStr;
@property (nonatomic, strong) NSString          * userDataStr;
@property (nonatomic, strong) NSString          * uuidStr;
@property (nonatomic, assign) BOOL isDynamic;
@end

#pragma mark - Singleton
static JYTools *bleTool = nil;

@implementation JYTools

#pragma mark - 懒加载
- (NSMutableArray *)deviceArr {
    if (!_bleMArray) {
        _bleMArray = [NSMutableArray array];
    }
    
    return _bleMArray;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue =  dispatch_queue_create("jy.ble", NULL);
        _Manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:nil];
    }
    return self;
}


+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleTool = [[self alloc] init];
    });
    
    return bleTool;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleTool = [super allocWithZone:zone];
    });
    
    return bleTool;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}

- (void)scanDevice {
    [self.deviceArr removeAllObjects];
    // 这里的第一个参数设置为nil，就扫描所有的设备，如果只想返回特定的服务的设备，就给服务的数组
    [DynamicEncryptor sharedInstance].beginDynamicCheck = NO;
    [DynamicEncryptor sharedInstance].hasSendMsg = NO;
    [_Manager scanForPeripheralsWithServices:nil options:nil];
}

- (void)stopScan {
    [_Manager stopScan];
}

- (void)connectDevice:(CBPeripheral *)peripheral {
    self.currentPer = peripheral;
    // 请求连接到此外设
    [_Manager connectPeripheral:peripheral options:nil];
}

- (void)unConnectDevice {
    [self.Manager cancelPeripheralConnection:self.currentPer];
}

- (NSArray *)retrieveConnectedPeripherals {
    // 需要特定的服务UUID才能返回特定的已连接设备。
    return [_Manager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:self.uuidStr]]];
}


+ (void)setSSID:(NSString *)ssid {
    [JYTools shareInstance].ssidStr = ssid;
}


+ (void)setPassword:(NSString *)password {
    [JYTools shareInstance].passwordStr = password;
}


+ (void)setBLEName:(NSString *)bleName {
    [JYTools shareInstance].bleStr = bleName;
}


+ (void)setUserData:(NSString *)userData {
    [JYTools shareInstance].userDataStr = userData;
}


+ (NSString *)getSSID {
    return [JYTools shareInstance].ssidStr;
}


+ (NSString *)getPassword {
    return [JYTools shareInstance].passwordStr;
}

+ (void)setDynamic:(BOOL)dynamic {
    [JYTools shareInstance].isDynamic = dynamic;
    [DynamicEncryptor sharedInstance].beginDynamicCheck = NO;
    [DynamicEncryptor sharedInstance].hasSendMsg = NO;
}


+ (NSString *)getBleName {
    return [JYTools shareInstance].bleStr;
}


+ (NSString *)getUserData {
    return [JYTools shareInstance].userDataStr;
}

+ (NSMutableArray *)getPostData {
    return [JYTools shareInstance].frames;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        [_Manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
        if ([self.discoverDelegate respondsToSelector:@selector(BLEIsSuccesee:)]) {
            [self.discoverDelegate BLEIsSuccesee:@"蓝牙已打开"];
        }
    } else if (central.state == CBManagerStatePoweredOff) {
        if ([self.discoverDelegate respondsToSelector:@selector(BLEIsSuccesee:)]) {
            [self.discoverDelegate BLEIsSuccesee:@"蓝牙未打开"];
        }
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@">>>扫描到设备:%@",advertisementData);
    
    if ([advertisementData[@"kCBAdvDataLocalName"] isEqualToString:_bleStr]) {
        [self.bleMArray addObject:peripheral];
        
        self.uuidStr = [NSString stringWithFormat:@"%@", peripheral.identifier];
        
        if ([self.discoverDelegate respondsToSelector:@selector(BLEDidDiscoverDeviceWithMAC:)]) {
            // 返回扫描到的设备实例
            [self.discoverDelegate BLEDidDiscoverDeviceWithMAC:peripheral];
        }
    }
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if ([self.discoverDelegate respondsToSelector:@selector(BLEIsSuccesee:)]) {
        [self.discoverDelegate BLEIsSuccesee:[NSString stringWithFormat:@"连接到名称为(%@)的设备 - 成功",[peripheral name]]];
    }
    
    peripheral.delegate = self;

    self.currentPer = peripheral;

    NSLog(@"connected, to discover services");
    [peripheral discoverServices:@[[CBUUID UUIDWithString:@"0000fee7-0000-1000-8000-00805f9b34fb"]]];
    
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([self.discoverDelegate respondsToSelector:@selector(BLEIsSuccesee:)]) {
        [self.discoverDelegate BLEIsSuccesee:[NSString stringWithFormat:@"连接到名称为(%@)的设备 - 失败,原因:%@",[peripheral name],[error localizedDescription]]];
    }
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([self.discoverDelegate respondsToSelector:@selector(BLEIsSuccesee:)]) {
        [self.discoverDelegate BLEIsSuccesee:[NSString stringWithFormat:@"断开BLE连接"]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@" service == %@ ---", peripheral.services);
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"0000fee7-0000-1000-8000-00805f9b34fb"]]) {
            //查找特征
            [self.currentPer discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"chari == %@ ---", service.characteristics);
    
    // write
    for (CBCharacteristic *character in service.characteristics) {
        // 写 CBCharacteristic
        if ([character.UUID isEqual:[CBUUID UUIDWithString:@"0000fec7-0000-1000-8000-00805f9b34fb"]]) {
            self.writeCharacteristic = character;
        }
        
        // 通知
        if ([character.UUID isEqual:[CBUUID UUIDWithString:@"0000fec8-0000-1000-8000-00805f9b34fb"]]) {
            self.notifyCharacteristic = character;
            [self.currentPer setNotifyValue:YES forCharacteristic:character];
        }
    }
    if (!self.isDynamic) {
        [self archiver];
    } else {
        if (![DynamicEncryptor sharedInstance].beginDynamicCheck) {
            [[DynamicEncryptor sharedInstance] connectBleStartCheck];
            [self.currentPer writeValue:[DynamicEncryptor sharedInstance].negotiationFrame forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
        } else {
      
        }
    }
    
    // 组装
//    [self archiver];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@">>>>%@,>>>>>>%@,>>>>>>>%@",peripheral, characteristic, error);
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        
    } else {
        NSData *responseData = characteristic.value;
        NSString * str  =[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        BOOL isSuccess = [str containsString:@"success"];
        if (self.isDynamic){
            if ([DynamicEncryptor sharedInstance].beginDynamicCheck && responseData != nil) {
                if ([[DynamicEncryptor sharedInstance].dynamicState isEqualToString:@"start"] && responseData.length == [DynamicEncryptor sharedInstance].confirmData.length + 1) {
                    //
                    NSData *responseData1 = [responseData subdataWithRange:NSMakeRange(1, responseData.length - 1)];
                    NSData *confirmData = [DynamicEncryptor sharedInstance].confirmData;
                    if ([responseData1 isEqualToData:confirmData]) {
                        NSLog(@"动态密码交换成功");
                        [DynamicEncryptor sharedInstance].dynamicState= @"getmac";
                        [self getDeviceMac];
                        return;
                    } else {
                        NSLog(@"蓝牙校验失败");
                    }
                } else if ([[DynamicEncryptor sharedInstance].dynamicState isEqualToString:@"getmac"]){
                    NSData *data = [responseData subdataWithRange:NSMakeRange(0, responseData.length)];
                    [self parseRecvData:data];
                } else if ([[DynamicEncryptor sharedInstance].dynamicState isEqualToString:@"sendmsg"]){
                    NSData *data = [responseData subdataWithRange:NSMakeRange(0, responseData.length)];
                    [self parseRecvData:data];
                }else {
                    NSLog(@"......current receive succ:%@",[[NSNumber alloc] initWithBool:isSuccess]);
                    if (isSuccess) {
                        [self.currentPer writeValue:[@"config_ack" dataUsingEncoding: NSUTF8StringEncoding] forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
                    }
                }
            }
        }else{
            NSData *data = [responseData subdataWithRange:NSMakeRange(0, responseData.length)];
            [self parseRecvData:data];
        }
        if (isSuccess) {
            [self.currentPer writeValue:[@"config_ack" dataUsingEncoding: NSUTF8StringEncoding] forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
        }
        
    }
}

NSMutableData *recvAllData;
- (void) parseRecvData:(NSData *)data{
    [self logData:data];
    Byte *b = (Byte *)[data bytes];
    int seqNo= b[0];
    int seqNum= b[1];
    int dlen= b[2];
    if (seqNo==1){
        recvAllData=[[NSMutableData alloc] init];
    }
    if (seqNo<=seqNum && dlen<=0x15){
        [recvAllData appendBytes:&b[3] length:dlen];
    }
    if (seqNo==seqNum){
        [self logData:recvAllData];
        if (self.isDynamic){
            if ([[DynamicEncryptor sharedInstance].dynamicState isEqualToString:@"getmac"]){
                Byte *btmp= (Byte *)[recvAllData bytes];
                NSMutableData *encrypt= [[NSMutableData alloc] init];
                if (btmp[0]==0xfe){
                    [encrypt appendBytes:&btmp[2] length:btmp[1]];
                    [self logData:encrypt];
                    NSData *decryptData= [[DynamicEncryptor sharedInstance] getDecryptData:encrypt];
                    Byte *bmac= (Byte *)[decryptData bytes];
                    NSMutableString *mac = [NSMutableString string];
                    if (decryptData.length==6){
                        for (int i = 0; i < 6; i++)
                        {
                            NSString *itemStr = [NSString stringWithFormat:@"%02X",(unsigned char)bmac[i]];
                            [mac appendString:itemStr];
                        }
                        if ([self.discoverDelegate respondsToSelector:@selector(BLEDidGetDeviceMac:)]){
                            [self.discoverDelegate BLEDidGetDeviceMac:mac];
                        }
                    }
                }
            }else if ([[DynamicEncryptor sharedInstance].dynamicState isEqualToString:@"sendmsg"]){
                Byte *btmp= (Byte *)[recvAllData bytes];
                NSMutableData *encrypt= [[NSMutableData alloc] init];
                if (btmp[0]==0xfe){
                    [encrypt appendBytes:&btmp[2] length:btmp[1]];
                    [self logData:encrypt];
                    NSData *decryptData= [[DynamicEncryptor sharedInstance] getDecryptData:encrypt];
                    [self logData:decryptData];
                    [self parseMessage:decryptData];
                }
            }
        }else{
            NSLog(@"not dynamic, ble recv!");
            Byte *btmp= (Byte *)[recvAllData bytes];
            NSMutableData *encrypt= [[NSMutableData alloc] init];
            if (btmp[0]==0xfe){
                [encrypt appendBytes:&btmp[2] length:btmp[1]];
                [self logData:encrypt];
                NSData *decryptData = [TeaEncryptor TeaDecrypt:encrypt withKey:@"hiflying12345678"];
                if (decryptData!=nil){
                    [self logData:decryptData];
                    [self parseMessage:decryptData];
                }
            }
        }
    }
}

// BLE接收wifi连接状态
- (void)parseMessage:(NSData *)msgData{
    NSError *err;
    NSDictionary *dic= [NSJSONSerialization JSONObjectWithData:msgData options:NSJSONReadingMutableLeaves error:&err];
    if (err){
        NSLog(@"error:%@", err);
        return ;
    }
    NSString *mid, *mac, *ip, *errStr;
    BOOL state= true;
    NSMutableArray *arr = [NSMutableArray array];
    for (id key in dic){
        if ([key isEqualToString:@"mid"]){
            mid= [dic objectForKey:key];
//            mid= [[dic objectForKey:@"mid"] stringValue];
            NSLog(@"MID=%@",mid);
        }else if ([key isEqualToString:@"mac"]){
            mac= [dic objectForKey:@"mac"];
            NSLog(@"MAC=%@",mac);
        }else if ([key isEqualToString:@"ip"]){
            ip= [dic objectForKey:@"ip"];
            NSLog(@"IP=%@",ip);
        }else if ([key isEqualToString:@"err"]){
            state= false;
            errStr= [dic objectForKey:@"err"];
            NSLog(@"errStr=%@",errStr);
        }
    }
    if (state==true){
        [arr addObject:ip];
        [arr addObject:mac];
    }else{
        [arr addObject:errStr];
    }
    if ([self.discoverDelegate respondsToSelector:@selector(BLEDidFinishedWithResult:andPara:)]){
        [self.discoverDelegate BLEDidFinishedWithResult:state andPara:arr];
    }
}

// 发送消息请求设备MAC地址
- (void)getDeviceMac{
    NSMutableData *plainData= [[NSMutableData alloc] init];
    Byte b[]= {0xac, 0xcf, 0x23, 0xff, 0x88, 0x88};
    [plainData appendBytes:b length:6];
    [self logData:plainData];
    NSData *encryptorData;
    encryptorData = [[DynamicEncryptor sharedInstance] getEncryptData:plainData];
    [self logData:encryptorData];
    NSMutableData *allMData = [[NSMutableData alloc] init];
    Byte head[]= {0xfe, encryptorData.length};
    [allMData appendBytes:head length:2];
    [allMData appendData:encryptorData];
    [self logData:allMData];
    [self bleSendData:allMData];
    
//    NSData *decrypt=[[DynamicEncryptor sharedInstance] getDecryptData:encryptorData];
//    [self logData:decrypt];
}

- (void) setUserDataAndContinue:(NSString *)userData{
    [JYTools shareInstance].userDataStr = userData;
    [DynamicEncryptor sharedInstance].dynamicState= @"sendmsg";
    [self archiver];
}

- (void)archiver {
    NSMutableData *allMData = [[NSMutableData alloc] init];
    
    NSData *ssidData = [[JYTools getSSID] dataUsingEncoding: NSUTF8StringEncoding];
    NSData *passwordData = [[JYTools getPassword] dataUsingEncoding: NSUTF8StringEncoding];
    NSData *userData = [[JYTools getUserData] dataUsingEncoding:NSUTF8StringEncoding];
    
    Byte ssidLen[] = {ssidData.length & 0xFF};
    Byte passwordLen[] = {passwordData.length & 0xFF};
    Byte userLen[] = {userData.length & 0xFF};
    
    Byte *ssidByte = (Byte *)[ssidData bytes];
    Byte *passwordByte = (Byte *)[passwordData bytes];
    Byte *userByte = (Byte *)[userData bytes];
    
    [allMData appendBytes:ssidLen length:1];
    if (ssidData.length > 0) {
        [allMData appendBytes:ssidByte length:ssidData.length];
    }
    
    [allMData appendBytes:passwordLen length:1];
    if (passwordData.length > 0) {
        [allMData appendBytes:passwordByte length:passwordData.length];
    }
    
    [allMData appendBytes:userLen length:1];
    if (userData.length > 0) {
        [allMData appendBytes:userByte length:userData.length];
    }
    
    Byte crcByte[] = {[CRC crc8Maxim:allMData]};
    [allMData appendBytes:crcByte length:1];
    [self logData:allMData];
    NSData *encryptorData;
    if (self.isDynamic) {
        encryptorData = [[DynamicEncryptor sharedInstance] getEncryptData:allMData];
        NSLog(@"dynamic");
    } else {
        encryptorData = [TeaEncryptor TeaEncrypt:allMData withKey:@"hiflying12345678"];
        
        NSData *temp = [TeaEncryptor TeaDecrypt:encryptorData withKey:@"hiflying12345678"];
        NSLog(@"send data: decrypt:");
        [self logData:temp];
    }
//    NSData *encryptorData = [TeaEncryptor TeaEncrypt:allMData withKey:@"hiflying12345678"];
    //
//    CocoaSecurityResult *resultData = [CocoaSecurity aesEncryptWithData:allMData key:[DynamicEncryptor sharedInstance].deviceKeyData iv:[DynamicEncryptor sharedInstance].deviceKeyData];
//    NSData *encryptorData = resultData.data;
//                                       [self logData:encryptorData];
//    NSData *encryptorData = [[DynamicEncryptor sharedInstance] getEncryptData:allMData];
    NSLog(@"encrypt data:");
    [self logData:encryptorData];
    [self bleSendData:encryptorData];
//    NSData *dtmp=[[DynamicEncryptor sharedInstance] getDecryptData:encryptorData];
//    [self logData:dtmp];
//    NSInteger dataLength = encryptorData.length;
//    NSInteger frameCount = dataLength/17;
//    if (dataLength % 17 != 0) {
//        frameCount++;
//    }
//
//    NSInteger position = 0;
//
//    NSMutableArray *array = [NSMutableArray array];
//
//    for (int i = 0; i < frameCount; i++) {
//        NSInteger frameDataLength = dataLength - position > 17 ? 17 : dataLength - position;
//
//        Byte frame[] = {(i + 1) & 0xFF};
//        Byte frame2[] = {frameCount & 0xFF};
//        Byte frame3[] = {frameDataLength & 0xFF};
//
//        NSData *datas = [encryptorData subdataWithRange:NSMakeRange(position, frameDataLength)];
//        Byte *frame4 = (Byte *)[datas bytes];
//
//        NSMutableData *temp = [[NSMutableData alloc] init];
//
//        [temp appendBytes:frame length:1];
//        [temp appendBytes:frame2 length:1];
//        [temp appendBytes:frame3 length:1];
//        [temp appendBytes:frame4 length:datas.length];
//        // 02 02 04 32 33 00 CD
//        [array addObject:temp];
//
//        position += frameDataLength;
//    }
//
//    [JYTools shareInstance].frames = array;
//
//    for (int j = 0;j < array.count;j++) {//CBCharacteristicWriteWithResponse
//        [self.currentPer writeValue:array[j] forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
//    }
}

- (void)bleSendData:(NSData *)data{
    NSInteger dataLength = data.length;
    NSInteger frameCount = dataLength/17;
    if (dataLength % 17 != 0) {
        frameCount++;
    }

    NSInteger position = 0;

    NSMutableArray *array = [NSMutableArray array];

    for (int i = 0; i < frameCount; i++) {
        NSInteger frameDataLength = dataLength - position > 17 ? 17 : dataLength - position;
        
        Byte frame[] = {(i + 1) & 0xFF};
        Byte frame2[] = {frameCount & 0xFF};
        Byte frame3[] = {frameDataLength & 0xFF};
        
        NSData *datas = [data subdataWithRange:NSMakeRange(position, frameDataLength)];
        Byte *frame4 = (Byte *)[datas bytes];
        
        NSMutableData *temp = [[NSMutableData alloc] init];
        
        [temp appendBytes:frame length:1];
        [temp appendBytes:frame2 length:1];
        [temp appendBytes:frame3 length:1];
        [temp appendBytes:frame4 length:datas.length];
        // 02 02 04 32 33 00 CD
        [array addObject:temp];

        position += frameDataLength;
    }

    [JYTools shareInstance].frames = array;
    
    for (int j = 0;j < array.count;j++) {//CBCharacteristicWriteWithResponse
        [self.currentPer writeValue:array[j] forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
    }
}

- (void)logData:(NSData *)data {
    NSMutableString *result = [NSMutableString string];
    const char *bytes = [data bytes];
     for (int i = 0; i < [data length]; i++)
     {
         NSString *itemStr = [NSString stringWithFormat:@"%02hhx",(unsigned char)bytes[i]];
//         [result appendFormat:@"%02hhx", (unsigned char)bytes[i]];
         [result appendString:itemStr];
     }
    NSLog(@"result str:%@ ", result);
}

@end
