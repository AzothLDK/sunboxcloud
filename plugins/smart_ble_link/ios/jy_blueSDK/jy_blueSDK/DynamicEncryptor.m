//
//  DynamicEncryptor.m
//  jy_blueSDK
//
//  Created by apple on 2022/4/14.
//  Copyright © 2022 Mr Simetrio. All rights reserved.
//

#import "DynamicEncryptor.h"
#import "aes_util.h"

@implementation DynamicEncryptor


+ (instancetype)sharedInstance {
    static DynamicEncryptor *_instance;
    static dispatch_once_t _predicate;
    dispatch_once(&_predicate, ^{
        //
        _instance = [[DynamicEncryptor alloc] init];
        _instance.confirmKey = @"ConfirmationKey";
    });
    return  _instance;
}

- (NSData *) getDecryptData:(NSData *)recvData{
    int inLen= (int)recvData.length;//32;
    uint8_t *cryptData = (uint8_t*)[recvData bytes];
    int out_len = 0;
    UInt8 ccmKey[32];
    memcpy(ccmKey, self.deviceKeyData.bytes, 16);
    memcpy(ccmKey + 16, self.confirmData.bytes, 16);
    [self logData:ccmKey andLen:32];
    unsigned char *resultChar = decrypt_ccm(cryptData, inLen, &out_len, ccmKey, 256);
    NSLog(@"out_len=%d", out_len);
    return [NSData dataWithBytes:resultChar length:out_len];
}

/*
 * 获取动态加密后的数据
 */
- (NSData *)getEncryptData:(NSData *)wifiData {
    NSData * resData = wifiData;
    BOOL canAliquot = NO;//wifiData.length % 16 == 0
    if (canAliquot) {
        int row = wifiData.length / 16 + 1;
        UInt8 cryptTxtBytes[16 *row];
        uint8_t *cryptTxt = (uint8_t*)[wifiData bytes];
        for (int i = 0; i < row * 16; i++) {
            //
            if (i < wifiData.length) {
                cryptTxtBytes[i] = cryptTxt[i];
            } else {
                cryptTxtBytes[i] = 0;
            }
        }
        int cryptTxtLen= 16 * row;//32;
        int out_len = 0;
        UInt8 ccmKey[32];
        memcpy(ccmKey, self.deviceKeyData.bytes, 16);
        memcpy(ccmKey + 16, self.confirmData.bytes, 16);
        unsigned char *resultChar = encrypt_ccm(cryptTxtBytes, cryptTxtLen, &out_len, ccmKey, 256);
        return [NSData dataWithBytes:resultChar length:out_len];
//        NSString *dd = @"";
//        char *dddd = [dd UTF8String];
//        memcpy(dddd, self.deviceKeyData, 16);
//
//        UInt8 outTxt[cryptTxtLen + 16];
////        UInt8 plainTxt[cryptTxtLen];
//        memcpy(<#void *__dst#>, <#const void *__src#>, <#size_t __n#>)
//        aes_encrypt(cryptTxtBytes, cryptTxtLen, outTxt, cryptTxtLen + 16, self.deviceKeyData.bytes);
//        return [NSData dataWithBytes:outTxt length:cryptTxtLen];
    } else {
        int cryptTxtLen= (int)wifiData.length;//32;
        uint8_t *cryptTxtBytes = (uint8_t*)[wifiData bytes];
        int out_len = 0;
        UInt8 ccmKey[32];
        memcpy(ccmKey, self.deviceKeyData.bytes, 16);
        memcpy(ccmKey + 16, self.confirmData.bytes, 16);
//        [self logData:ccmKey andLen:32];
        unsigned char *resultChar = encrypt_ccm(cryptTxtBytes, cryptTxtLen, &out_len, ccmKey, 256);
        return [NSData dataWithBytes:resultChar length:out_len];
//        UInt8 outTxt[16 + cryptTxtLen];
//        UInt8 plainTxt[cryptTxtLen];
//        //
//        aes_encrypt(cryptTxt, cryptTxtLen, outTxt, cryptTxtLen + 16, self.deviceKeyData.bytes);
//        return [NSData dataWithBytes:outTxt length:sizeof(cryptTxtLen)];
    }
}

- (void)logData:(Byte *)b andLen:(int)len {
    NSMutableString *result = [NSMutableString string];
     for (int i = 0; i < len; i++)
     {
         NSString *itemStr = [NSString stringWithFormat:@"%02X ",(unsigned char)b[i]];
//         [result appendFormat:@"%02hhx", (unsigned char)bytes[i]];
         [result appendString:itemStr];
     }
    NSLog(@"ccm key:%@ ", result);
}

/*
 * 蓝牙连接后开始校验
 */
- (void)connectBleStartCheck {
    self.beginDynamicCheck = YES;
    self.hasSendMsg = NO;
    self.dynamicState= @"start";
    NSString *randomA = [self randomString:8];
    NSString *randomB = [self randomString:8];
    self.randomA = randomA;
    self.randomB = randomB;
    [self configNegotiationFrame];
    [self configGenKeyData];
    [self configGenS1Data];
    [self configGenS2Data];
    [self configConfirmData];
    [self configDeviceKeyData];
}



//普通字符串转换为十六进制的。

- (NSString *)hexStringFromString:(NSString *)string{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
        
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        
        else
            
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}



- (NSString *)randomString:(NSInteger)number {
    
    NSString *ramdom;
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 1; i ; i ++) {
        int a = (arc4random() % 122);
        if (a > 96) {
            char c = (char)a;
            [array addObject:[NSString stringWithFormat:@"%c",c]];
            if (array.count == number) {
                break;
            }
        } else continue;
    }
    ramdom = [array componentsJoinedByString:@""];
    return ramdom;
}

- (void)configNegotiationFrame {
    UInt8 bytes[17];
    bytes[0] = 0XFF;
    NSString *str = [NSString stringWithFormat:@"%@%@",self.randomA,self.randomB];
    for (NSInteger i = 0; i< str.length; i++) {
                NSString *hexadecimalItemStr = [self hexStringFromString:[str substringWithRange:NSMakeRange(i, 1)]];
                UInt8 itemInt= (UInt8)strtoul([hexadecimalItemStr UTF8String], 0, 16);
//        UInt8 byte = (UInt8)strtoul([obj UTF8String],0,16);
        bytes[i+1] = itemInt;
    }
    //
    //
    self.negotiationFrame = [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (void)configGenKeyData {
    NSString *genKey = [NSString stringWithFormat:@"%@%@%@",self.randomA,self.randomB,self.confirmKey];
//    self.genKeyData = [self getAesData:genKey input:48 outPut:32];
    self.genKeyData = [self getAesData:genKey input:32 outPut:32];
    //
    NSLog(@"kkkkey.....%ld",self.genKeyData.length);
}

- (void)configGenS1Data {
    NSString *genKey = [NSString stringWithFormat:@"%@%@",self.randomA,self.randomB];
//    self.genS1Data = [self getAesData:genKey input:48 outPut:32];
    self.genS1Data = [self getAesData:genKey input:16 outPut:32];
    NSLog(@"kkkk.....%ld",self.genS1Data.length);
}

- (void)configConfirmData {
    UInt8 data[48];
    NSString *str = [NSString stringWithFormat:@"%@%@",self.randomA,self.randomB];
    for (NSInteger i = 0; i< str.length; i++) {
                NSString *hexadecimalItemStr = [self hexStringFromString:[str substringWithRange:NSMakeRange(i, 1)]];
                UInt8 itemInt= (UInt8)strtoul([hexadecimalItemStr UTF8String], 0, 16);
//        UInt8 byte = (UInt8)strtoul([obj UTF8String],0,16);
        data[i] = itemInt;
    }
    
    NSString *genKey = [NSString stringWithFormat:@"%@%@%@",self.randomA,self.randomB,self.confirmKey];
    //
    UInt8 genBytes[48];
    for (NSInteger i = 0; i< genKey.length; i++) {
                NSString *hexadecimalItemStr = [self hexStringFromString:[genKey substringWithRange:NSMakeRange(i, 1)]];
                UInt8 itemInt= (UInt8)strtoul([hexadecimalItemStr UTF8String], 0, 16);
//        UInt8 byte = (UInt8)strtoul([obj UTF8String],0,16);
        genBytes[i] = itemInt;
    }
    UInt8 genBytesOut[32];
    cal_sha256(genBytes, genKey.length, genBytesOut);
    //
    
    UInt8 s1BytesOut[32];
    
    cal_sha256(data, str.length, s1BytesOut);
    //
    for (NSInteger i = 0; i< 32; i++) {
        data[i+16] = s1BytesOut[i];
    }
    UInt8 confirmBytes[16];
    aes_util_cmac(data, 48, genBytesOut, confirmBytes);
//    int state = aes_cmac(genBytesOut, data, 48, confirmBytes);
    self.confirmData = [NSData dataWithBytes:confirmBytes length:sizeof(confirmBytes)];
    NSLog(@"kkkkjjjjcccc.....%ld",self.confirmData.length);
}

- (void)configDeviceKeyData {
    UInt8 data[48];
    NSString *str = [NSString stringWithFormat:@"%@%@",self.randomB,self.randomA];
    for (NSInteger i = 0; i< str.length; i++) {
                NSString *hexadecimalItemStr = [self hexStringFromString:[str substringWithRange:NSMakeRange(i, 1)]];
                UInt8 itemInt= (UInt8)strtoul([hexadecimalItemStr UTF8String], 0, 16);
//        UInt8 byte = (UInt8)strtoul([obj UTF8String],0,16);
        data[i] = itemInt;
    }
    //先拿到s2
    UInt8 s2BytesOut[32];
    
    cal_sha256(data, str.length, s2BytesOut);
    //
    
    NSString *genKey = [NSString stringWithFormat:@"%@%@%@",self.randomA,self.randomB,self.confirmKey];
    //
    UInt8 genBytes[48];
    for (NSInteger i = 0; i< genKey.length; i++) {
                NSString *hexadecimalItemStr = [self hexStringFromString:[genKey substringWithRange:NSMakeRange(i, 1)]];
                UInt8 itemInt= (UInt8)strtoul([hexadecimalItemStr UTF8String], 0, 16);
//        UInt8 byte = (UInt8)strtoul([obj UTF8String],0,16);
        genBytes[i] = itemInt;
    }
    UInt8 genBytesOut[32];
    cal_sha256(genBytes, genKey.length, genBytesOut);
    //拿到key

    //
    for (NSInteger i = 0; i< 32; i++) {
        data[i+16] = s2BytesOut[i];
    }
    UInt8 deviceByteOuts[16];
    aes_util_cmac(data, 48, genBytesOut, deviceByteOuts);
//    int state = aes_cmac(genBytesOut, data, 48, deviceByteOuts);
    self.deviceKeyData = [NSData dataWithBytes:deviceByteOuts length:sizeof(deviceByteOuts)];
    NSLog(@"kkkkjjjjccccdddd.....%ld",self.deviceKeyData.length);
}

- (void)configGenS2Data {
    NSString *genKey = [NSString stringWithFormat:@"%@%@",self.randomB,self.randomA];
//    self.genS2Data = [self getAesData:genKey input:48 outPut:32];
    self.genS2Data = [self getAesData:genKey input:16 outPut:32];
    NSLog(@"kkkkjjjj.....%ld",self.genS2Data.length);
}

- (NSData *)getAesData:(NSString *)str input:(int)inputLen outPut:(int)outLen {
    UInt8 bytes[inputLen];
    for (NSInteger i = 0; i< str.length; i++) {
                NSString *hexadecimalItemStr = [self hexStringFromString:[str substringWithRange:NSMakeRange(i, 1)]];
                UInt8 itemInt= (UInt8)strtoul([hexadecimalItemStr UTF8String], 0, 16);
//        UInt8 byte = (UInt8)strtoul([obj UTF8String],0,16);
        bytes[i] = itemInt;
    }
    UInt8 bytesOut[outLen];
    cal_sha256(bytes, str.length, bytesOut);
    //
    return [NSData dataWithBytes:bytesOut length:sizeof(bytesOut)];
}

@end
