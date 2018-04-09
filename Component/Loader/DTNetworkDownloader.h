//
//  DTNetworkDownloader.h
//  ImageBrowser
//
//  Created by dubhe on 2018/3/13.
//  Copyright © 2018年 Dubhe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DTDownloadDataCompletion)(NSURL *fileURL, NSURL *videoURL, NSData *data, NSError *error);
typedef void (^DTDwonloadDataReciveResponse)(NSURL *fileURL);
typedef void (^DTDownloadDataReciveData)(NSURL *fileURL, NSURL *videoURL, NSData *data);
typedef void (^DTDownloadProgressCallBack)(NSURL *videoURL, float progress);




@interface DTNetworkDownloader : NSObject


@property (nonatomic) NSUInteger retryTimes;
@property (nonatomic) NSTimeInterval timeoutInterval;
//http://f.us.sinaimg.cn/002cQaPhlx07jwzJ015e01040200OzNR0k010.mp4?label=mp4_hd&template=852x480.28&Expires=1523285001&ssig=P3c3WohUzL&KID=unistore,video
- (void)dataWithURLString:(NSString *)URLString progress:(DTDownloadProgressCallBack)progressCallBack reciveResponse:(DTDwonloadDataReciveResponse)reciveResponse reciveData:(DTDownloadDataReciveData)reciveData  completion:(DTDownloadDataCompletion)completion;
- (void)dataWithURLString:(NSString *)URLString completion:(DTDownloadDataCompletion)completion;
+ (NSString *)cacheDirectory;
+ (NSString *)cacheFilePathForURL:(NSString *)URL;
+ (void)clearCache;

@end
