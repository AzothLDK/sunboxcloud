//
//  GTransfromer.m
//  jy_blueSDK
//
//  Created by Mr Simetrio on 2019/6/17.
//  Copyright © 2019 Mr Simetrio. All rights reserved.
//

#import "GTransfromer.h"

@implementation GTransfromer

+ (NSMutableArray *)bytes2ints:(NSData *)data {
    
    NSData *dataF = [[NSData alloc] init];
    unsigned int returnValue = 0;
    NSMutableArray *array = [NSMutableArray array];
    
    NSInteger len = data.length/4;
    
    for (int i = 0; i<len; i++) {
        dataF = [data subdataWithRange:NSMakeRange(4*i, 4)];
        
        Byte *byte = (Byte *)[dataF bytes];
        
        int byteCount = sizeof(byte)/2;
        for (int i=0; i<byteCount; i++) {
            if (i == 0) {
                returnValue = byte[byteCount -1];
            } else {
                returnValue += pow(256, i) * byte[byteCount-i-1];
            }
        }
        [array addObject:[NSNumber numberWithUnsignedInt:returnValue]];
    }
    
    return array;
}

@end
