//
//  DTNetworkDownloader.m
//  ImageBrowser
//
//  Created by dubhe on 2018/3/13.
//  Copyright © 2018年 Dubhe. All rights reserved.
//

#import "DTNetworkDownloader.h"
#import "DTUtil.h"

@import MobileCoreServices;

@interface DTNetworkDownloaderTask : NSObject

@property (nonatomic, strong) NSURLSessionTask           *task;
@property (nonatomic, strong) NSURLRequest               *request;
@property (nonatomic, copy)   DTDownloadDataCompletion   completion;
@property (nonatomic, copy)   DTDownloadDataReciveData   reciveData;
@property (nonatomic, copy)   DTDwonloadDataReciveResponse reciveResponse;
@property (nonatomic, copy)   DTDownloadProgressCallBack progressCallBack;
@property (nonatomic, strong) NSMutableData              *data;
@property (nonatomic, assign) NSUInteger                 totalLength;
@property (nonatomic, assign) NSUInteger                 retryTimes;

@end

@implementation DTNetworkDownloaderTask

@end

@interface DTNetworkDownloader () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSOperationQueue *sessionQueue;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMapTable *reqTable;
@property (nonatomic, strong) NSMapTable *taskTable;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) NSUInteger maxConcurrentOperationCount;
@property (nonatomic, strong) dispatch_queue_t gcd_queue;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation DTNetworkDownloader

- (instancetype)init
{
    if (self = [super init])
    {
        _lock = [[NSLock alloc] init];
        _gcd_queue                         = dispatch_queue_create(nil, nil);
        _queue                             = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
        _queue.name                        = [NSStringFromClass([self class]) stringByAppendingString:@"Queue"];
        _semaphore                         = dispatch_semaphore_create(0);
        [self setup];
    }
    return self;
}

- (void)setup {
    self.reqTable                                 = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    self.taskTable                                = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    self.sessionQueue                             = [[NSOperationQueue alloc] init];
    self.sessionQueue.name                        = [NSStringFromClass([self class]) stringByAppendingString:@"Queue"];
    self.sessionQueue.maxConcurrentOperationCount = 20;
    self.session                                  = [NSURLSession
                                                     sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                     delegate:self
                                                     delegateQueue:self.sessionQueue];
    self.timeoutInterval                          = 30;
    self.retryTimes                               = 3;
    self.queue.maxConcurrentOperationCount = 20;
}

- (void)dataWithURLString:(NSString *)URLString progress:(DTDownloadProgressCallBack)progressCallBack reciveResponse:(DTDwonloadDataReciveResponse)reciveResponse reciveData:(DTDownloadDataReciveData)reciveData  completion:(DTDownloadDataCompletion)completion {
   
    if (!([URLString hasPrefix:@"http://"] || [URLString hasPrefix:@"https://"])) {
        NSError *error = [NSError errorWithDomain:@"DTDownloaderError" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"InvalidRequest"}];
        completion(nil ,[NSURL URLWithString:URLString], nil, error);
        return;
    }
#warning 缓存中查询是否下载逻辑
    //缓存中查询
    
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URLString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeoutInterval];
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request];
    DTNetworkDownloaderTask *downloaderTask = [[DTNetworkDownloaderTask alloc] init];
    downloaderTask.task = task;
    downloaderTask.request = request;
    downloaderTask.completion = completion;
    downloaderTask.progressCallBack = progressCallBack;
    downloaderTask.reciveData = reciveData;
    downloaderTask.reciveResponse = reciveResponse;
    downloaderTask.data = [NSMutableData data];
    [self.lock lock];
    //    [self.reqTable setObject:downloaderTask forKey:request.keyForLoader];
    [self.taskTable setObject:downloaderTask forKey:@(task.taskIdentifier)];
    [self.lock unlock];
    
    [task resume];
}


- (void)dataWithURLString:(NSString *)URLString completion:(DTDownloadDataCompletion)completion {
    [self dataWithURLString:URLString progress:nil reciveResponse:nil reciveData:nil completion:completion];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    self.reqTable = nil;
    self.taskTable = nil;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if (!self.contentInfo) {
        DTContentInfo *contentInfo = [[DTContentInfo alloc] init];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            
            NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)response;
            NSString *acceptRange = HTTPURLResponse.allHeaderFields[@"Accept-Ranges"];
            contentInfo.byteRangeAccessSupported = [acceptRange isEqualToString:@"bytes"];
            contentInfo.contentLength = [[[HTTPURLResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
            
            NSString *mimeType = response.MIMEType;
            CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
            contentInfo.contentType = CFBridgingRelease(contentType);
            
            self.contentInfo = contentInfo;
            
//            NSHTTPURLResponse *rsp = (NSHTTPURLResponse *) response;
//            NSString *num          = rsp.allHeaderFields[@"Content-Length"];
//            if ([num isKindOfClass:[NSString class]])
//            {
//                [self.lock lock];
//                DTNetworkDownloaderTask *downloaderTask = [self.taskTable objectForKey:@(dataTask.taskIdentifier)];
//                [self.lock unlock];
//                downloaderTask.totalLength                   = [num integerValue];
//                if (downloaderTask.reciveResponse) {
//                    downloaderTask.reciveResponse(downloaderTask.request.URL);
//                }
//            }
        }
    }
    if ([self.delegate respondsToSelector:@selector(downloader:didReceiveResponse:)]) {
        [self.delegate downloader:self didReceiveResponse:response];
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    if ([self.delegate respondsToSelector:@selector(downloader:didRecieveData:)]) {
        [self.delegate downloader:self didRecieveData:data];
    }
    
    
//    [self.lock lock];
//    DTNetworkDownloaderTask *downloaderTask = [self.taskTable objectForKey:@(dataTask.taskIdentifier)];
//    [self.lock unlock];
//    DTDownloadDataCompletion completion      = downloaderTask.completion;
//    DTDownloadProgressCallBack progressCallBack = downloaderTask.progressCallBack;
//    DTDownloadDataReciveData reciveDataCallBack = downloaderTask.reciveData;
//    NSMutableData *recvdata                  = downloaderTask.data;
//    NSURLRequest *request                    = downloaderTask.request;
//    [recvdata appendData:data];
//
//    if (reciveDataCallBack) {
//        reciveDataCallBack(request.URL, request.URL, data);
//    }
//
//    if (progressCallBack)
//    {
//        float progress = recvdata.length / (float) downloaderTask.totalLength;
//        if (progress > 1)
//        {
//            progress = 1;
//            progressCallBack(request.URL,progress);
//            if (completion) {
//                completion(request.URL, request.URL, recvdata, nil);
//            }
//        }
//        if (isinf(progress))
//        {
//            progress = 0;
//            progressCallBack(request.URL,progress);
//        }
//        if (progress < 1)
//        {
//            progressCallBack(request.URL,progress);
//        }
//    } else if (completion) {
//        float progress = recvdata.length / (float) downloaderTask.totalLength;
//        if (progress > 1)
//        {
//            progress = 1;
//        }
//        if (isinf(progress))
//        {
//            progress = 0;
//        }
//        if (progress < 1)
//        {
//            completion(request.URL, request.URL, recvdata, nil);
//        }
//    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(downloader:didCompleteWithError:)]) {
        [self.delegate downloader:self didCompleteWithError:error];
    }
    
//
//    [self.lock lock];
//    DTNetworkDownloaderTask *downloaderTask = [self.taskTable objectForKey:@(task.taskIdentifier)];
//    [self.lock unlock];
//    if (!downloaderTask)
//    {
//        return;
//    }
//
//    DTDownloadDataCompletion completion = downloaderTask.completion;
//    DTDownloadProgressCallBack progressCallBack = downloaderTask.progressCallBack;
//    NSMutableData *data          = downloaderTask.data;
//    NSURLRequest *request        = downloaderTask.request;
//    [self.lock lock];
////    [self.reqTable removeObjectForKey:request.keyForLoader];
//    [self.taskTable removeObjectForKey:@(task.taskIdentifier)];
//    [self.lock unlock];
//    NSURL *fileURL = [NSURL fileURLWithPath:[DTNetworkDownloader cacheFilePathForURL:request.URL.absoluteString]];
//    if (error)
//    {
//        if (error.code != NSURLErrorCancelled)
//        {
//            if (downloaderTask.retryTimes < self.retryTimes)
//            {
//                downloaderTask.retryTimes++;
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), self.gcd_queue, ^{
//                    [self dataWithURLString:request.URL.absoluteString completion:completion];
//                });
//            }
//            else
//            {
//                if (completion)
//                {
//                    completion(fileURL, request.URL, nil, error);
//                }
//            }
//
//        }
//        else
//        {
//            if (completion)
//            {
//                completion(fileURL, request.URL, nil, error);
//            }
//        }
//    }
//    else
//    {
//        [data writeToURL:fileURL atomically:YES];
//        if (progressCallBack) {
//            progressCallBack(fileURL, 1);
//        }
//        if (completion)
//        {
//            completion(fileURL, request.URL, data, error);
//        }
//    }
}

+ (NSString *)cacheDirectory
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
                      stringByAppendingPathComponent:@"videos/"];
    
    return path;
}

+ (NSString *)cacheFilePathForURL:(NSString *)URL
{
    NSString *path = [self cacheDirectory];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:true
                                               attributes:nil
                                                    error:nil];
    return [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [DTUtil MD5:URL]]];
}

+ (void)clearCache
{
    [NSFileManager.defaultManager removeItemAtPath:[self cacheDirectory] error:nil];
}


- (void)dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;
    self.reqTable = nil;
    self.taskTable = nil;
}

@end
