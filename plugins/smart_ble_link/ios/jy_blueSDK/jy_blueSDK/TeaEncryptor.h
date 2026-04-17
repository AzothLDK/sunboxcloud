//
//  TeaEncryptor.h
//  jy_BluetoothSDK
//
//  Created by Mr Simetrio on 2019/6/5.
//  Copyright © 2019 Mr Simetrio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeaEncryptor : NSObject

+ (NSString *)encrypt:(NSString *)plaintext withPassword:(NSString *)password;
+ (NSString *)decrypt:(NSString *)ciphertext withPassword:(NSString *)password;

+ (NSData *)TeaEncrypt:(NSMutableData *)data withKey:(NSString *)key;
+ (NSData *)TeaDecrypt:(NSMutableData *)data withKey:(NSString *)key;

@end
