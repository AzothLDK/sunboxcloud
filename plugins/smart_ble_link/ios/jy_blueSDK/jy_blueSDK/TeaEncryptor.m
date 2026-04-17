//
//  TeaEncryptor.m
//  jy_BluetoothSDK
//
//  Created by Mr Simetrio on 2019/6/5.
//  Copyright © 2019 Mr Simetrio. All rights reserved.
//

#import "TeaEncryptor.h"
#import "GTransfromer.h"

@interface TeaEncryptor ()

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
+ (NSString *)base64EncodedStringFromData:(NSData *)data;
+ (NSData *)base64DecodedString:(NSString *)string;
#endif

+ (NSMutableArray *)bytesToLongs:(const char *)bytes ofLength:(NSUInteger)length;
+ (unsigned char *)longsToBytes:(NSArray *)longs;

@end

@implementation TeaEncryptor
+ (NSData *)TeaDecrypt:(NSMutableData *)data withKey:(NSString *)key{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    int len = (int)(data.length / 8) * 8;
    NSData *data1 = [data subdataWithRange:NSMakeRange(0, len)];
    
    int otherLen = (int)data.length - len;
    NSData *otherData = [data subdataWithRange:NSMakeRange(len, otherLen)];
    Byte *keyByte3 = (Byte *)[otherData bytes];
    
    NSMutableArray *array1 = [NSMutableArray array];
    array1 = [GTransfromer bytes2ints:keyData];
    
    NSMutableArray *array2 = [NSMutableArray array];
    array2 = [GTransfromer bytes2ints:data1];
    
    NSMutableData *allMData = [[NSMutableData alloc] init];
    NSData *dataa = [[NSData alloc] init];
    NSData *datab = [[NSData alloc] init];
    
    for (int i = 0; i < array2.count; i += 2){
        unsigned delta = 0x9e3779b9;
        unsigned sum = 0;
        
        unsigned a = [array2[i] unsignedIntValue];
        unsigned b = [array2[i + 1] unsignedIntValue];
        
        sum= delta << 3;
        for (int j = 0; j < 8; j++) {
            b -= (a<<4) + [array1[2] unsignedIntValue] ^ a + sum ^ (a>>5) + [array1[3] unsignedIntValue];
            a -= (b<<4) + [array1[0] unsignedIntValue] ^ b + sum ^ (b>>5) + [array1[1] unsignedIntValue];
            sum-= delta;
        }
        
        dataa = [NSData dataWithBytes:&a length:sizeof(a)];
        datab = [NSData dataWithBytes:&b length:sizeof(b)];
        
        if (dataa.length > 0) {
            NSMutableData *changeDataa = [[NSMutableData alloc] init];
            for (NSInteger i = dataa.length - 1; i >= 0; i--) {
                NSData *tempData = [dataa subdataWithRange:NSMakeRange(i, 1)];
                [changeDataa appendData:tempData];
            }
            [allMData appendBytes:(Byte *)[changeDataa bytes] length:changeDataa.length];
        }
        
        if (datab.length > 0) {
            NSMutableData *changeDatab = [[NSMutableData alloc] init];
            for (NSInteger i = datab.length - 1; i >= 0; i--) {
                NSData *tempData = [datab subdataWithRange:NSMakeRange(i, 1)];
                [changeDatab appendData:tempData];
            }
            [allMData appendBytes:(Byte *)[changeDatab bytes] length:changeDatab.length];
        }
    }
    [allMData appendBytes:keyByte3 length:otherData.length];
    return allMData;
}

+ (NSData *)TeaEncrypt:(NSMutableData *)data withKey:(NSString *)key {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    int len = (int)(data.length / 8) * 8;
    NSData *data1 = [data subdataWithRange:NSMakeRange(0, len)];
    
    int otherLen = (int)data.length - len;
    NSData *otherData = [data subdataWithRange:NSMakeRange(len, otherLen)];
    Byte *keyByte3 = (Byte *)[otherData bytes];
    
    NSMutableArray *array1 = [NSMutableArray array];
    array1 = [GTransfromer bytes2ints:keyData];
    
    NSMutableArray *array2 = [NSMutableArray array];
    array2 = [GTransfromer bytes2ints:data1];

    NSMutableData *allMData = [[NSMutableData alloc] init];
    NSData *dataa = [[NSData alloc] init];
    NSData *datab = [[NSData alloc] init];
    
    for (int i = 0; i < array2.count; i += 2) {

        unsigned delta = 0x9e3779b9;
        unsigned sum = 0;
        
        unsigned a = [array2[i] unsignedIntValue];
        unsigned b = [array2[i + 1] unsignedIntValue];

        for (int j = 0; j < 8; j++) {

            sum += delta;
            
            a += ((b << 4) + [array1[0] unsignedIntValue]) ^ (b + sum) ^ ((b >> 5) + [array1[1] unsignedIntValue]);
            b += ((a << 4) + [array1[2] unsignedIntValue]) ^ (a + sum) ^ ((a >> 5) + [array1[3] unsignedIntValue]);
        }
        
        dataa = [NSData dataWithBytes:&a length:sizeof(a)];
        datab = [NSData dataWithBytes:&b length:sizeof(b)];
        
        if (dataa.length > 0) {
            NSMutableData *changeDataa = [[NSMutableData alloc] init];
            for (NSInteger i = dataa.length - 1; i >= 0; i--) {
                NSData *tempData = [dataa subdataWithRange:NSMakeRange(i, 1)];
                [changeDataa appendData:tempData];
            }
            [allMData appendBytes:(Byte *)[changeDataa bytes] length:changeDataa.length];
        }
        
        if (datab.length > 0) {
            NSMutableData *changeDatab = [[NSMutableData alloc] init];
            for (NSInteger i = datab.length - 1; i >= 0; i--) {
                NSData *tempData = [datab subdataWithRange:NSMakeRange(i, 1)];
                [changeDatab appendData:tempData];
            }
            [allMData appendBytes:(Byte *)[changeDatab bytes] length:changeDatab.length];
        }
    }
    
    [allMData appendBytes:keyByte3 length:otherData.length];
//8E E7 51 1A 6E 79 58 55 A0 83 1E 01 99 AE BA 89 31 32 33 00 CD
    return allMData;
}

+ (NSMutableArray *)bytesToLongs:(const char *)bytes ofLength:(NSUInteger)length
{
    int slen = (int)length;
    int len = (int)ceil(((double)slen) / 4.0);
    NSMutableArray * l = [NSMutableArray arrayWithCapacity:length];
    __uint32_t ll, lll;
    for (int i = 0; i < len; i++)
    {
        lll = 0;
        ll = i * 4;
        if (ll < slen) lll += ((unsigned char)bytes[ll]);
        ll = i * 4 + 1;
        if (ll < slen) lll += ((unsigned char)bytes[ll]) << 8;
        ll = i * 4 + 2;
        if (ll < slen) lll += ((unsigned char)bytes[ll]) << 16;
        ll = i * 4 + 3;
        if (ll < slen) lll += ((unsigned char)bytes[ll]) << 24;
        [l addObject:[NSNumber numberWithUnsignedInt:lll]];
    }
    return l;
}

+ (unsigned char *)longsToBytes:(NSArray *)longs
{
    unsigned char *a = malloc(longs.count * 4);
    unsigned char *p = a;
    __uint32_t ll;
    for (NSUInteger i = 0, len = longs.count; i < len; i++)
    {
        ll = [[longs objectAtIndex:i] unsignedIntValue];
        (*(p++)) = (unsigned char)(ll & 0xFF);
        (*(p++)) = (unsigned char)(ll >> 8 & 0xFF);
        (*(p++)) = (unsigned char)(ll >> 16 & 0xFF);
        (*(p++)) = (unsigned char)(ll >> 24 & 0xFF);
    }
    return a;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

+ (NSData *)base64DecodedString:(NSString *)string
{
    NSMutableData *mutableData = nil;
    
    if (string)
    {
        unsigned long ixtext = 0;
        unsigned long lentext = 0;
        unsigned char ch = 0;
        unsigned char inbuf[4] = {0}, outbuf[3];
        short i = 0, ixinbuf = 0;
        BOOL flignore = NO;
        BOOL flendtext = NO;
        NSData *base64Data = nil;
        const unsigned char *base64Bytes = nil;
        
        // Convert the string to ASCII data.
        base64Data = [string dataUsingEncoding:NSASCIIStringEncoding];
        base64Bytes = [base64Data bytes];
        mutableData = [NSMutableData dataWithCapacity:base64Data.length];
        lentext = base64Data.length;
        
        while (YES)
        {
            if (ixtext >= lentext) break;
            ch = base64Bytes[ixtext++];
            flignore = NO;
            
            if ( ( ch >= 'A' ) && ( ch <= 'Z' ) ) ch = ch - 'A';
            else if ( ( ch >= 'a' ) && ( ch <= 'z' ) ) ch = ch - 'a' + 26;
            else if ( ( ch >= '0' ) && ( ch <= '9' ) ) ch = ch - '0' + 52;
            else if ( ch == '+' ) ch = 62;
            else if ( ch == '=' ) flendtext = YES;
            else if ( ch == '/' ) ch = 63;
            else flignore = YES;
            
            if (!flignore)
            {
                short ctcharsinbuf = 3;
                BOOL flbreak = NO;
                
                if (flendtext)
                {
                    if (!ixinbuf) break;
                    ctcharsinbuf = ((ixinbuf == 1) || (ixinbuf == 2)) ? 1 : 2;
                    ixinbuf = 3;
                    flbreak = YES;
                }
                
                inbuf [ixinbuf++] = ch;
                
                if (ixinbuf == 4)
                {
                    ixinbuf = 0;
                    outbuf [0] = ( inbuf[0] << 2 ) | ( ( inbuf[1] & 0x30) >> 4 );
                    outbuf [1] = ( ( inbuf[1] & 0x0F ) << 4 ) | ( ( inbuf[2] & 0x3C ) >> 2 );
                    outbuf [2] = ( ( inbuf[2] & 0x03 ) << 6 ) | ( inbuf[3] & 0x3F );
                    
                    for (i = 0; i < ctcharsinbuf; i++)
                    {
                        [mutableData appendBytes:&outbuf[i] length:1];
                    }
                }
                
                if (flbreak) break;
            }
        }
    }
    
    return mutableData;
}

+ (NSString *)base64EncodedStringFromData:(NSData *)data
{
    const unsigned char    *bytes = [data bytes];
    NSMutableString *result = [NSMutableString stringWithCapacity:data.length];
    unsigned long ixtext = 0;
    unsigned long lentext = data.length;
    long ctremaining = 0;
    unsigned char inbuf[3], outbuf[4];
    short i = 0;
    short ctcopy = 0;
    unsigned long ix = 0;
    
    static char encodingTable[64] = {
        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
        'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
        'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
        'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };
    
    while (YES)
    {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0) break;
        
        for (i = 0; i < 3; i++)
        {
            ix = ixtext + i;
            inbuf[i] = ix < lentext ? bytes[ix] : 0;
        }
        
        outbuf [0] = (inbuf [0] & 0xFC) >> 2;
        outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
        outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
        outbuf [3] = inbuf [2] & 0x3F;
        ctcopy = 4;
        
        switch( ctremaining )
        {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }
        
        for (i = 0; i < ctcopy; i++)
        {
            [result appendFormat:@"%c", encodingTable[outbuf[i]]];
        }
        
        for (i = ctcopy; i < 4; i++)
        {
            [result appendFormat:@"%c",'='];
        }
        
        ixtext += 3;
    }
    
    return result;
}

#endif

+ (NSString *)encrypt:(NSString *)plaintext withPassword:(NSString *)password
{
    if (plaintext.length == 0) return @"";
    const char *utf = [plaintext UTF8String];
    const char *utfPwd = [password UTF8String];
    NSMutableArray *v = [self bytesToLongs:utf ofLength:strlen(utf)];
    while (v.count <= 1) [v addObject:[NSNumber numberWithInt:0]];
    NSMutableArray *k = [self bytesToLongs:utfPwd ofLength:strlen(utfPwd)];
    while (k.count < 4) [k addObject:[NSNumber numberWithInt:0]];
    int n = (int)v.count;
    
    __uint32_t z = [[v objectAtIndex:n-1] unsignedIntValue], y, sum = 0, e, DELTA = (__int32_t)0x9e3779b9, mx;
    __int32_t p, q;
    
    q = 6 + 52 / n;
    
    while (q-- > 0)
    {
        sum += DELTA;
        e = (sum >> 2) & 3;
        for (p = 0; p < n; p++)
        {
            y = [[v objectAtIndex:(p + 1) % n] unsignedIntValue];
            mx = ((z >> 5) ^ (y << 2)) +
            ((y >> 3) ^ (z << 4)) ^ (sum ^ y) +
            ([[k objectAtIndex:((p & 3) ^ e)] unsignedIntValue] ^ z);
            
            [v replaceObjectAtIndex:p withObject:[NSNumber numberWithUnsignedInt:[[v objectAtIndex:p] unsignedIntValue] + mx]];
            
            z = [[v objectAtIndex:p] unsignedIntValue];
        }
    }
    unsigned char *bytes = [self longsToBytes:v];
    NSData *data = [NSData dataWithBytes:bytes length:v.count * 4];
    free(bytes);
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    return [self base64EncodedStringFromData:data];
#else
    return [data base64EncodedStringWithOptions:0];
#endif
}

//+ (NSData *)TeaDecrypt:(NSMutableData *)data withKey:(NSString *)key{
//    if (data.length == 0) return nil;
//    const char *utfPwd = [key UTF8String];
//    NSMutableArray *v = [self bytesToLongs:(const char *)data.bytes ofLength:data.length];
//    NSMutableArray *k = [self bytesToLongs:utfPwd ofLength:strlen(utfPwd)];
//    while (k.count < 4) [k addObject:[NSNumber numberWithInt:0]];
//
//    NSMutableArray * rv = [NSMutableArray arrayWithCapacity:v.count];
//
//    for (int j=0; j<v.count-2; j+=2){
//        __uint32_t y= [[v objectAtIndex:j+0] unsignedIntValue], z=[[v objectAtIndex:j+1] unsignedIntValue], sum=0, DELTA=(__int32_t)0x9e3779b9;
//        __uint32_t a=[[k objectAtIndex:0] unsignedIntValue], b= [[k objectAtIndex:1] unsignedIntValue];
//        __uint32_t c=[[k objectAtIndex:2] unsignedIntValue], d=[[k objectAtIndex:3] unsignedIntValue];
//        sum= DELTA * 32;
//        for (int i=0; i<32; i++){
//            z-=((y<<4)+c) ^ (y+sum)^((y>>5)+d);
//            y-= ((z<<4) +a) ^ (z+sum)^((z>>5)+b);
//            sum-=DELTA;
//        }
//        [rv addObject:[NSNumber numberWithUnsignedInt:y]];
//        [rv addObject:[NSNumber numberWithUnsignedInt:z]];
//    }
//
//    unsigned char * plaintext = [self longsToBytes:rv];
//    NSString * result = [NSString stringWithUTF8String:(const char *)plaintext];
//    free(plaintext);
//    NSData *retData= [result dataUsingEncoding:NSUTF8StringEncoding];
//    return retData;
//}

+ (NSString *)decrypt:(NSString *)ciphertext withPassword:(NSString *)password
{
    if (ciphertext.length == 0) return @"";
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    NSData *base64decoded = [self base64DecodedString:ciphertext];
#else
    NSData *base64decoded = [[NSData alloc] initWithBase64EncodedString:ciphertext options:0];
#endif
    
    const char *utfPwd = [password UTF8String];
    NSMutableArray *v = [self bytesToLongs:(const char *)base64decoded.bytes ofLength:base64decoded.length];
    NSMutableArray *k = [self bytesToLongs:utfPwd ofLength:strlen(utfPwd)];
    while (k.count < 4) [k addObject:[NSNumber numberWithInt:0]];
    int n = (int)v.count;
    
    __uint32_t z, y = [[v objectAtIndex:0] unsignedIntValue], sum, e , DELTA = (__int32_t)0x9e3779b9, mx;
    __int32_t p, q;
    
    q = 6 + 52 / n;
    
    sum = q * DELTA;
    
    while (sum != 0)
    {
        e = sum >> 2 & 3;
        for (p = n - 1; p >= 0; p--)
        {
            z = [[v objectAtIndex:p > 0 ? p - 1 : n - 1] intValue];
            mx = ((z >> 5) ^ (y << 2)) +
            ((y >> 3) ^ (z << 4)) ^ (sum ^ y) +
            ([[k objectAtIndex:((p & 3) ^ e)] unsignedIntValue] ^ z);
            
            [v replaceObjectAtIndex:p withObject:[NSNumber numberWithUnsignedInt:[[v objectAtIndex:p] unsignedIntValue] - mx]];
            
            y = [[v objectAtIndex:p] unsignedIntValue];
        }
        sum -= DELTA;
    }
    
    [v addObject:[NSNumber numberWithUnsignedInt:0]]; // null terminator
    unsigned char * plaintext = [self longsToBytes:v];
    
    NSString * result = [NSString stringWithUTF8String:(const char *)plaintext];
    free(plaintext);
    return result;
}

@end
