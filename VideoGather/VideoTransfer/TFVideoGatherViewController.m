//
//  TFVideoGatherViewController.m
//  VideoGather
//
//  Created by shiwei on 17/9/11.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFVideoGatherViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <LFLiveKit/LFLiveKit.h>

//TODO:对视频数据的处理是否可以使用流水线的设计模式，把某一种处理，如滤镜、裁剪等，作为一个单独的处理环节，然后配置处理环节，可以很方便的决定需要哪些效果以及先后顺序。video data ->[滤镜1][滤镜2][分辨率拉伸][大小裁剪][编码][输入文件]--->文件

@interface TFVideoGatherViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, LFLiveSessionDelegate>{
    AVCaptureSession *_session;
    AVCaptureVideoDataOutput *_videoDataOutput;
    dispatch_queue_t _videoDataOutQueue;
    
    AVCaptureVideoPreviewLayer *_previewlayer;
    
    
    LFLiveSession *_LFSession;
    UIView *_LFPreView;
    LFLiveStreamInfo *_streamInfo;
}

@end

@implementation TFVideoGatherViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self setupSession];
    [self setupPreview];
    [self setupLFSession];
}

-(BOOL)setupSession{
    _session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [_session setSessionPreset:AVCaptureSessionPreset640x480];
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] firstObject] error:&error];
    if (error) {
        NSLog(@"Video device is error: %@",error);
        return NO;
    }
    
    [_session addInput:videoInput];
    
    _previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    
    _videoDataOutQueue = dispatch_queue_create("video_data_output_queue", 0);
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutQueue];
    
    return YES;
}

-(void)setupPreview{
    _LFPreView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200)];
    _LFPreView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:_LFPreView];
}

-(void)setupLFSession{
    
    LFLiveAudioConfiguration *audioConfig = [LFLiveAudioConfiguration defaultConfiguration];
    LFLiveVideoConfiguration *videoConfg = [LFLiveVideoConfiguration defaultConfiguration];
    
    _LFSession = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfig videoConfiguration:videoConfg captureType:LFLiveCaptureMaskVideo];
    _LFSession.delegate = self;
    _LFSession.running = YES;
    _LFSession.preView = _LFPreView;
    _LFSession.beautyFace = YES;
    _LFSession.captureDevicePosition = AVCaptureDevicePositionBack;
    
    
    _streamInfo = [[LFLiveStreamInfo alloc] init];
    _streamInfo.url = @"rtmp://192.168.0.70:1935/gzhm/room";
    [_LFSession startLive:_streamInfo];
}

#pragma mark - video data output delegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
}

@end
