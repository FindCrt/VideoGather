//
//  TFCameraViewController.m
//  VideoGather
//
//  Created by shiwei on 17/8/31.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "TFMediaListViewController.h"
#import "VRVideoEncoder.h"
#import "TFPhotoAlbumWriter.h"
#import "TFVideoPlayerViewController.h"
#import "TFMediaDataAnalyzer.h"

#define ScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define UsingVideoEncoder   1

@interface TFCameraViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>{
    AVCaptureSession *_session;
    dispatch_queue_t _videoOutputQueue;
    
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureMovieFileOutput *_fileOutput;
    
    UIButton *_recordButton;
    
#if UsingVideoEncoder
    VRVideoEncoder *_videoEncoder;
    AVCaptureVideoDataOutput *_dataOutput;
    BOOL _encodeEnable;
    
    CMTime _currentPts;
    CGSize _outputSize;
#endif
}

@property (nonatomic, copy) NSString *recordPath;

@end

@implementation TFCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //TODO:1. 屏幕scale是否影响 2. size小于原数据时，是重新采样还是裁剪
    _outputSize = CGSizeMake(640, 480);
    
    [self configureCameraSession];
//    [self setupCaptureSession];
//    [self setupUI];
//    [self setupEncoder];
    
//    [self startSession];
}

-(void)setupCaptureSession{
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPreset640x480;
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureInput *videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:videoDevice error:&error];
    [_session addInput:videoInput];
    
    _videoOutputQueue = dispatch_queue_create("video_data_output_queue", DISPATCH_QUEUE_SERIAL);
    
}

-(void)startSession{
    [_session startRunning];
}

-(void)setupUI{
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"recorded" style:(UIBarButtonItemStylePlain) target:self action:@selector(showRecordVideoList)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self setupPreview];
    
    CGFloat recordWidth = 100, recordHeight = 40;
    _recordButton = [[UIButton alloc] initWithFrame:CGRectMake((ScreenWidth-recordWidth)/2.0, CGRectGetMaxY(_previewLayer.frame)+15, recordWidth, recordHeight)];
    [_recordButton setTitle:@"record" forState:(UIControlStateNormal)];
    [_recordButton setTitle:@"recording..." forState:(UIControlStateSelected)];
    [_recordButton setBackgroundColor:[UIColor colorWithWhite:0.95 alpha:1]];
    [_recordButton setTitleColor:[UIColor darkTextColor] forState:(UIControlStateNormal)];
    [_recordButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateSelected)];
    [_recordButton addTarget:self action:@selector(recordAndEncode:) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self.view addSubview:_recordButton];
    
}

-(void)setupPreview{
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _previewLayer.frame = CGRectMake(10, 100, self.view.frame.size.width - 20, 200);
    
    
//    _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    [self.view.layer addSublayer:_previewLayer];
}

-(void)recordControl:(UIButton *)button{
    button.selected = !button.selected;
    if (button.selected) {
        [button setBackgroundColor:[UIColor orangeColor]];
        
        if (_fileOutput == nil) {
            _fileOutput = [[AVCaptureMovieFileOutput alloc] init];
            [_session addOutput:_fileOutput];
            
            AVCaptureConnection *connection = [_fileOutput connectionWithMediaType:AVMediaTypeVideo];
        }
        
        [self genNewRecordPath];
        [_fileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:self.recordPath] recordingDelegate:self];
        
    }else{
        
        [button setBackgroundColor:[UIColor colorWithWhite:0.95 alpha:1]];
        
        [_fileOutput stopRecording];
    }
}

-(void)genNewRecordPath{
    
    NSString *filename = [NSString stringWithFormat:@"video%ld.mp4",(NSInteger)[[NSDate date] timeIntervalSince1970]];
    NSString *recordDir = [self recordDir];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:recordDir isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:recordDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"create director (%@) error: %@",recordDir,error);
            _recordPath = nil;
        }
    }
    
    _recordPath = [recordDir stringByAppendingPathComponent:filename];
}

-(NSString *)recordDir{
    
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documentDir stringByAppendingString:@"/recordedVideos"];
}

-(void)browseRecordedVideos{
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.recordPath] includingPropertiesForKeys:nil options:0 error:nil];
    
    NSLog(@"recorded:\n%@",files);
}

-(void)showRecordVideoList{
    TFMediaListViewController *mediaListVC = [[TFMediaListViewController alloc] init];
    mediaListVC.mediaDir = [self recordDir];
    mediaListVC.selectHandler = ^(TFMediaData *mediaData){
        TFVideoPlayerViewController *videoPlayerVC = [[TFVideoPlayerViewController alloc]init];
        videoPlayerVC.videoURL = [NSURL fileURLWithPath:mediaData.filePath];
        
        
        //[self presentViewController:videoPlayerVC animated:YES completion:nil];
        [self.navigationController pushViewController:videoPlayerVC animated:YES];

    };
    [self.navigationController pushViewController:mediaListVC animated:YES];
}

#pragma mark - video encoder

-(void)setupEncoder{
    _videoEncoder = [[VRVideoEncoder alloc] init];
    [self genNewRecordPath];
    [_videoEncoder setupWithOutputPath:self.recordPath videoSize:CGSizeMake(_outputSize.width , _outputSize.height) timeScale:_currentPts.timescale startTime:_currentPts.value];
}

-(void)recordAndEncode:(UIButton *)button{
    
    button.selected = !button.selected;
    
    if (button.selected) {
        [button setBackgroundColor:[UIColor orangeColor]];
        
        
        if (!_dataOutput) {
            
            _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
            _dataOutput.alwaysDiscardsLateVideoFrames = YES;

            _dataOutput.videoSettings = @{
                                          (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                          };

            [_dataOutput setSampleBufferDelegate:self queue:_videoOutputQueue];
            [_session addOutput:_dataOutput];
            
            NSLog(@"%@",[_dataOutput availableVideoCVPixelFormatTypes]);
        }
        
        _encodeEnable = YES;
        
    }else{
        
        [button setBackgroundColor:[UIColor colorWithWhite:0.95 alpha:1]];
        _encodeEnable = NO;
        
        [_videoEncoder finishedRecording];
        
        [[TFPhotoAlbumWriter shareInstance]writeAssertToPhotoAlbumFrom:self.recordPath];
    }
}

#pragma mark - video data output delegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (_encodeEnable) {
        
        CMTime lastPts = _currentPts;
        _currentPts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        
        
        if (!_videoEncoder) {
            [self setupEncoder];
        }
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        NSLog(@"output pixel size: (%d, %d)",width, height);
        
        int64_t duration = CMTimeGetSeconds(CMSampleBufferGetDuration(sampleBuffer));
        if (duration <= 0 && lastPts.value > 0) {
            duration = CMTimeGetSeconds(CMTimeSubtract(_currentPts, lastPts));
        }
        [_videoEncoder encodeToH264ForPixelBuffer:pixelBuffer pts:_currentPts.value duration:duration];
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
}

#pragma mark - video file output delegate

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"start record to file: %@",fileURL);
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"finished record to file: %@ \nconnections: %@, \nerror:%@",outputFileURL, connections, error);
}

- (void)configureCameraSession{
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPreset640x480;
    
    [_session beginConfiguration];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if(!device){
        NSLog(@"device is null");
        return;
    }
    
    AVCaptureDeviceFormat *currentFormat;
    int frameRate = 60;
    for (AVCaptureDeviceFormat *format in device.formats)
    {
        NSArray *ranges = format.videoSupportedFrameRateRanges;
        AVFrameRateRange *frameRates = ranges[0];

        //CMVideoFormatDescriptionGet
        int fps = 0;
        int resolutionWidth = CMVideoFormatDescriptionGetDimensions(format.formatDescription).width;
        if(frameRates.maxFrameRate > 59 && resolutionWidth >= 1920){
            fps = 60;
            if(frameRates.maxFrameRate > 119){
                fps = 120;
            }
            if(frameRates.maxFrameRate > 239){
                fps = 240;
            }
            
            NSString *resolution;

            if(resolutionWidth > 1920){
                resolution = @"4K ";
            }
            else{
                resolution = [[NSNumber numberWithInt:CMVideoFormatDescriptionGetDimensions(format.formatDescription).height] stringValue];
                resolution = [resolution stringByAppendingString:@"p "];
            }
        }
    }
    
//    if(!currentFormat){
//        [self noValidCamera];
//        return;
//    }
    
//    _currentCameraFormat = _analysisViewController.currentCameraFormat;
//    if(_currentCameraFormat.fps == 0){
//        _currentCameraFormatIndex = 0;
//        _currentCameraFormat = _formatList[_currentCameraFormatIndex];
//        _analysisViewController.currentCameraFormat = _currentCameraFormat;
//        currentFormat = _currentCameraFormat.format;
//        frameRate = _currentCameraFormat.fps;
//    }
//    else{
//        currentFormat = _currentCameraFormat.format;
//        frameRate = _currentCameraFormat.fps;
//    }
    
//    NSString *resolution;
//    if(CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).width > 1920){
//        resolution = @"4K ";
//    }
//    else{
//        resolution = [[NSNumber numberWithInt:CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).height] stringValue];
//        resolution = [resolution stringByAppendingString:@"p "];
//    }
//    NSString *fps = [[NSNumber numberWithInt:frameRate] stringValue];
//    fps = [fps stringByAppendingString:@" FPS  ▼"];
    
//    [self.videoLabelButton setTitle:[resolution stringByAppendingString:fps] forState:UIControlStateNormal];
    
    currentFormat = [device activeFormat];
    
    
    
//    [device lockForConfiguration:nil];
//    device.activeFormat = currentFormat;
//    device.activeVideoMinFrameDuration = CMTimeMake(1, frameRate);
//    device.activeVideoMaxFrameDuration = CMTimeMake(1, frameRate);
//    [device unlockForConfiguration];
    
    //Input
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [_session addInput:input];
    
    
    
    //Output
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if([_session canAddOutput:movieFileOutput]){
        [_session addOutput:movieFileOutput];
    }
    
//    [self setMovieOutputOrientation];
    
    //Preview Layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = CGRectMake(10, 100, self.view.frame.size.width - 20, 200);
    [self.view.layer addSublayer:_previewLayer];
    
    AVCaptureConnection *connection = _previewLayer.connection;
    NSLog(@"connection.videoMaxScaleAndCropFactor : %.2f",connection.videoMaxScaleAndCropFactor);
    connection.videoScaleAndCropFactor = connection.videoMaxScaleAndCropFactor;
    
    [device videoZoomFactor];
    
//    _previewLayer.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    
    AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    if ([device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
        [_previewLayer.connection setPreferredVideoStabilizationMode:stabilizationMode];
    }
    
    [_session commitConfiguration];
    [_session startRunning];
    
}

@end
