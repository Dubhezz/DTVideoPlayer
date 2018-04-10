//
//  DTAssetResourceLoader.m
//  DTVideoPlayer
//
//  Created by dubhe on 2018/4/10.
//  Copyright © 2018年 Dubhe. All rights reserved.
//

#import "DTAssetResourceLoader.h"
#import "DTNetworkDownloader.h"

@interface DTAssetResourceLoader () <DTNetworkDownloaderDelegate>

@property (nonatomic, strong) NSMutableArray *resourceRequests;
@property (nonatomic, strong) DTNetworkDownloader *downloader;
@property (nonatomic, strong) AVAssetResourceLoadingRequest *request;

@end

@implementation DTAssetResourceLoader

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloader = [[DTNetworkDownloader alloc] init];
        _downloader.delegate = self;
    }
    return self;
}

#pragma -mark AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self loaderForRequest:loadingRequest];
    [self pendingRequest:loadingRequest];
    //请求request
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.resourceRequests removeObject:loadingRequest];
}

#pragma -mark private

- (NSMutableArray *)resourceRequests {
    if (!_resourceRequests) {
        _resourceRequests = [NSMutableArray array];
    }
    return _resourceRequests;
}
- (void)pendingRequest:(AVAssetResourceLoadingRequest *)request {
    [self.resourceRequests addObject:request];
}

#pragma -mark DTNetworkDownloaderDelegate
- (void)downloader:(DTNetworkDownloader *)downloader didReceiveResponse:(NSURLResponse *)response {
    [self fullfillContentInfo];
}

- (void)downloader:(DTNetworkDownloader *)downloader didRecieveData:(NSData *)data {
    [self.request.dataRequest respondWithData:data];
}

- (void)downloader:(DTNetworkDownloader *)downloader didCompleteWithError:(NSError *)error {
    if (error) {
        [self.request finishLoadingWithError:error];
    } else {
        [self.request finishLoading];
    }
}

#pragma -mark private

- (void)loaderForRequest:(AVAssetResourceLoadingRequest *)request {
    self.request = request;
    [self.downloader dataWithURLString:[self.request.request.URL absoluteString] completion:nil];
}

- (void)fullfillContentInfo {
    AVAssetResourceLoadingContentInformationRequest *contentInformationRequest = self.request.contentInformationRequest;
    if (self.downloader.contentInfo && !contentInformationRequest.contentType) {
        // Fullfill content information
    
        contentInformationRequest.contentType = self.downloader.contentInfo.contentType;
        contentInformationRequest.contentLength = self.downloader.contentInfo.contentLength;
        contentInformationRequest.byteRangeAccessSupported = self.downloader.contentInfo.byteRangeAccessSupported;
    }
}

@end
