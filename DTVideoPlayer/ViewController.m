//
//  ViewController.m
//  DTVideoPlayer
//
//  Created by dubhe on 2018/4/9.
//  Copyright © 2018年 Dubhe. All rights reserved.
//

#import "ViewController.h"
#import "DTNetworkDownloader.h"
#import "DTUtil.h"

@interface ViewController ()

/** 文件的总长度 */
@property (nonatomic, assign) NSInteger fileLength;
/** 当前下载长度 */
@property (nonatomic, assign) NSInteger currentLength;
/** 文件句柄对象 */
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *videoURLString = @"http://f.us.sinaimg.cn/002cQaPhlx07jwzJ015e01040200OzNR0k010.mp4?label=mp4_hd&template=852x480.28&Expires=1523285001&ssig=P3c3WohUzL&KID=unistore,video";
    DTNetworkDownloader *netWorkDownloader = [[DTNetworkDownloader alloc] init];
    [netWorkDownloader dataWithURLString:videoURLString progress:^(NSURL *videoURL, float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"---- %@ -----", @(progress));
        });
    } reciveResponse:^(NSURL *fileURL) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
                          stringByAppendingPathComponent:@"movs/"];
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:true
                                                   attributes:nil
                                                        error:nil];
        NSString *identifier = [[NSUUID UUID] UUIDString];
        NSString *videoTargetPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov",[DTUtil MD5:identifier]]];
        
        if (![manager fileExistsAtPath:videoTargetPath]) {
            // 如果没有下载文件的话，就创建一个文件。如果有下载文件的话，则不用重新创建(不然会覆盖掉之前的文件)
            [manager createFileAtPath:videoTargetPath contents:nil attributes:nil];
        }
        
        // 创建文件句柄
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:videoTargetPath];
    } reciveData:^(NSURL *fileURL, NSURL *videoURL, NSData *data) {
        [self.fileHandle seekToEndOfFile];
        // 向沙盒写入数据
        [self.fileHandle writeData:data];
    } completion:^(NSURL *fileURL, NSURL *videoURL, NSData *data, NSError *error) {
        NSLog(@"视频下载完成");
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
