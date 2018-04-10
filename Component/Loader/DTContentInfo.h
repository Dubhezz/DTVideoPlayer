//
//  DTContentInfo.h
//  DTVideoPlayer
//
//  Created by dubhe on 2018/4/10.
//  Copyright © 2018年 Dubhe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTContentInfo : NSObject <NSCoding>

@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, assign) BOOL byteRangeAccessSupported;
@property (nonatomic, assign) unsigned long long contentLength;
@property (nonatomic) unsigned long long downloadedContentLength;

@end
