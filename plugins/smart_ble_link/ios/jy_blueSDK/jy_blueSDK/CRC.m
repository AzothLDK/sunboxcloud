//
//  CRC.m
//  jy_BluetoothSDK
//
//  Created by Mr Simetrio on 2019/6/5.
//  Copyright © 2019 Mr Simetrio. All rights reserved.
//

#import "CRC.h"

static CRC *CRCS = nil;

@implementation CRC


+ (Byte)crc8Maxim:(NSMutableData *)data {
    Byte crc = 0;
    
    NSMutableArray *array = [NSMutableArray array];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes,
                                          NSRange byteRange,
                                          BOOL *stop) {
        
        for (NSUInteger i = 0; i < byteRange.length; ++i) {
            NSString *str = [NSString stringWithFormat:@"%02x", ((uint8_t*)bytes)[i]];
            [array addObject:str];
        }
    }];
    
    for (int i = 0; i < array.count ; i++) {
        
        const char *hexChar = [array[i] cStringUsingEncoding:NSUTF8StringEncoding];
        int hexNumber;
        sscanf(hexChar, "%x", &hexNumber);
        
        crc ^= hexNumber;
        
        for (int j = 0; j < 8; j++) {
            if ((crc & 0x01) == 0x01) {
                crc = (Byte)(((crc & 0xff)) >> 1);
                crc ^= 0x8C;
            } else {
                crc = (Byte)(((crc & 0xff)) >> 1);
            }
        }
    }
    
    NSString *ccc = [NSString stringWithFormat:@"%hhu", crc];
    int cdc = [ccc intValue];
    int hex = 0;
    if (cdc > 128) {
        hex = cdc - 256;
    } else {
        hex = cdc;
    }
    
    return hex;
}

@end
