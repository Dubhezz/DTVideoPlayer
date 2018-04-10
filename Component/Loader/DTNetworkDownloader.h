//
//  DTNetworkDownloader.h
//  ImageBrowser
//
//  Created by dubhe on 2018/3/13.
//  Copyright © 2018年 Dubhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTContentInfo.h"

typedef void (^DTDownloadDataCompletion)(NSURL *fileURL, NSURL *videoURL, NSData *data, NSError *error);
typedef void (^DTDwonloadDataReciveResponse)(NSURL *fileURL);
typedef void (^DTDownloadDataReciveData)(NSURL *fileURL, NSURL *videoURL, NSData *data);
typedef void (^DTDownloadProgressCallBack)(NSURL *videoURL, float progress);

@class DTNetworkDownloader;

@protocol DTNetworkDownloaderDelegate <NSObject>

- (void)downloader:(DTNetworkDownloader *)downloader didReceiveResponse:(NSURLResponse *)response;
- (void)downloader:(DTNetworkDownloader *)downloader didRecieveData:(NSData *)data;
- (void)downloader:(DTNetworkDownloader *)downloader didCompleteWithError:(NSError *)error;

@end

@interface DTNetworkDownloader : NSObject

@property (nonatomic, weak) id<DTNetworkDownloaderDelegate> delegate;
@property (nonatomic) NSUInteger retryTimes;
@property (nonatomic) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) DTContentInfo *contentInfo;

- (void)dataWithURLString:(NSString *)URLString progress:(DTDownloadProgressCallBack)progressCallBack reciveResponse:(DTDwonloadDataReciveResponse)reciveResponse reciveData:(DTDownloadDataReciveData)reciveData  completion:(DTDownloadDataCompletion)completion;
- (void)dataWithURLString:(NSString *)URLString completion:(DTDownloadDataCompletion)completion;
+ (NSString *)cacheDirectory;
+ (NSString *)cacheFilePathForURL:(NSString *)URL;
+ (void)clearCache;

@end
