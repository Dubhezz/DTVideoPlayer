//
//  DTUtil.m
//  ImageBrowser
//
//  Created by dubhe on 2018/3/16.
//  Copyright © 2018年 Dubhe. All rights reserved.
//

#import "DTUtil.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation DTUtil

+ (NSString *)MD5:(NSString *)str
{
    const char *cstr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, (CC_LONG) strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
}

@end
