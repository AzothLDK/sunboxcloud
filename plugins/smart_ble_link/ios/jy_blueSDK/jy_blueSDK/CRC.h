//
//  CRC.h
//  jy_BluetoothSDK
//
//  Created by Mr Simetrio on 2019/6/5.
//  Copyright © 2019 Mr Simetrio. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRC : NSObject

+ (Byte)crc8Maxim:(NSMutableData *)data;

@end

NS_ASSUME_NONNULL_END
