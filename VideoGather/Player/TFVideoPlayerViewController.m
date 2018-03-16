//
//  TFVideoPlayerViewController.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFVideoPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "TFVideoNormalControlView.h"
#import "TFAVPlayerControlForwarder.h"
#import "UIDevice+ForceRotate.h"
#import "TFCoreImageDisplayView.h"
#import "CIImage+Filter.h"

#define AVPlayerUseCoreImageFiler   0

#define ScreenWidth ([UIScreen mainScreen].bounds.size.width)

@interface TFVideoPlayerViewController ()<TFVideoControlViewScreenDelegate>{
    AVPlayer *_player;
    
#if AVPlayerUseCoreImageFiler
    TFCoreImageDisplayView *_playView;
    AVPlayerItemVideoOutput *_videoOutput;
#else
    AVPlayerLayer *_playLayer;
#endif
    
    TFVideoNormalControlView *_controlView;
    TFAVPlayerControlForwarder *_controlForwarder;
    
    UIInterfaceOrientationMask _supportOrientation;
}

@end

@implementation TFVideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    _supportOrientation = UIInterfaceOrientationMaskPortrait;
    
    [self setupPlayer];
    CGRect playFrame = CGRectMake(0, 0, ScreenWidth,240);
    
#if AVPlayerUseCoreImageFiler
    _playView = [[TFCoreImageDisplayView alloc] initWithFrame:playFrame];
    _playView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    [self.view addSubview:_playView];
    
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(videoDisplay:)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
#else
    _playLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playLayer.frame = playFrame;
    _playLayer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1].CGColor;
    [self.view.layer addSublayer:_playLayer];
#endif
    
    _controlView = [[TFVideoNormalControlView alloc] initWithFrame:playFrame];
    [self.view addSubview:_controlView];
    
    _controlForwarder = [[TFAVPlayerControlForwarder alloc] init];
    _controlForwarder.player = _player;
    _controlForwarder.controlView = _controlView;
    
    _controlView.controlDelegate = _controlForwarder;
    _controlView.screenDelegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    [_player play];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    CGRect playFrame;
    if (_supportOrientation == UIInterfaceOrientationMaskPortrait) {
        playFrame = CGRectMake(0, 0, ScreenWidth,240);
    }else{
        playFrame = self.view.bounds;
    }
#if AVPlayerUseCoreImageFiler
    _playView.frame = playFrame;
    _controlView.frame = playFrame;
#else
    _playLayer.frame = playFrame;
    _controlView.frame = playFrame;
#endif
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [_player pause];
}

-(void)setupPlayer{
    AVPlayerItem *playItem = [[AVPlayerItem alloc] initWithURL:self.videoURL];
    _player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:@""]];
    [_player replaceCurrentItemWithPlayerItem:playItem];
    
    [_player addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew) context:nil];
    
#if AVPlayerUseCoreImageFiler
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:@{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];
    [playItem addOutput:_videoOutput];
#endif
    
}

-(void)dealloc{
    [_player removeObserver:self forKeyPath:@"status"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusFailed) {
            NSLog(@"error: %@",_player.error);
        }
    }
}

-(void)videoDisplay:(CADisplayLink *)link{
#if AVPlayerUseCoreImageFiler
    CMTime itemTime = [_videoOutput itemTimeForHostTime:CACurrentMediaTime()];
    
    if ([_videoOutput hasNewPixelBufferForItemTime:itemTime]) {
        CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
        CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        
        CIImage *background = [CIImage imageWithColor:[CIColor colorWithRed:0.5 green:0.5 blue:0.5]];//[image filterBy:@"CITriangleKaleidoscope"];
        
        CGFloat radius = (long)[NSDate date].timeIntervalSinceReferenceDate % 32 / 32.0 * 200;
        NSLog(@"radius: %.1f",radius);
        CIImage *mask = [CIImage radialGradient:_playView.center radius:radius];
        _playView.image = [image blendWithMask:mask background:background];
    
    }
#endif
}



#pragma mark - video control view screen delegate

-(void)extendToFullScreen{
    _supportOrientation = UIInterfaceOrientationMaskLandscapeLeft;
    
    [UIDevice changeOrientation:(UIDeviceOrientationLandscapeLeft)];
}

-(void)shrinkFromFullScreen{
    _supportOrientation = UIInterfaceOrientationMaskPortrait;
    
    [UIDevice changeOrientation:(UIDeviceOrientationPortrait)];
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return _supportOrientation;
}

@end
