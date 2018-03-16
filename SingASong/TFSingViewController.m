//
//  TFSingViewController.m
//  VideoGather
//
//  Created by shiwei on 17/11/10.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFSingViewController.h"
#import "TFMusicListViewController.h"
#import "TFMediaDataAnalyzer.h"
#import "TFlyricPlayView.h"
#import "TFAudioUnitPlayer.h"
#import "TFAudioRecorder.h"
#import "TFAudioFileWriter.h"
#import "TFAudioMixer.h"
#import "TFAudioFileReader.h"
#import "TFMediaListViewController.h"

#define bottomHeight    70

@interface TFSingViewController (){
    TFMediaData *_curAccompany;
//    NSString *_recordPath;
    NSString *_mixedAudioPath;
    
    UIImageView *_musicCover;
    TFlyricPlayView *_lyricView;
    UIProgressView *_progressView;
    UIButton *_playStopButton;
    UIButton *_mixButton;
    UIButton *_showMixedButton;
    
    TFAudioUnitPlayer *_player;
    TFAudioRecorder *_recorder;
    TFAudioFileWriter *_recordWriter;
    TFAudioMixer *_mixer;
    
    TFAudioUnitPlayer *_mixedAudioPlayer;
    TFAudioFileWriter *_mixedAudioWriter;
}

@end

@implementation TFSingViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [self setupAudioComponents];
    
    [self setupUI];
    
    av_register_all();
}

-(void)setupUI{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.8 alpha:1];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.2 alpha:1]}];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    CGFloat leftSpace = 36;
    _musicCover = [[UIImageView alloc] initWithFrame:CGRectMake(leftSpace, 30, screenWidth-leftSpace*2, screenWidth-leftSpace*2)];
    _musicCover.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [self.view addSubview:_musicCover];
    
    _lyricView = [[TFlyricPlayView alloc] initWithFrame:CGRectMake(0 , CGRectGetMaxX(_musicCover.frame)+20, screenWidth, screenHeight - 64 - bottomHeight)];
    [self.view addSubview:_lyricView];
    
    
    
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight - 64 - bottomHeight, screenWidth, bottomHeight)];
    bottomBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bottomBar];
    
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, screenHeight, 3)];
    _progressView.trackTintColor = [UIColor whiteColor];
    _progressView.progressTintColor = [UIColor orangeColor];
    [bottomBar addSubview:_progressView];
    
    CGFloat playButtonWidth = 36;
    _playStopButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth/2.0-playButtonWidth/2.0, bottomHeight/2.0-playButtonWidth/2.0, playButtonWidth, playButtonWidth)];
    [_playStopButton setImage:[UIImage imageNamed:@"play"] forState:(UIControlStateNormal)];
    _playStopButton.backgroundColor = [UIColor clearColor];
    _playStopButton.layer.cornerRadius = playButtonWidth/2.0;
    _playStopButton.clipsToBounds = YES;
    [_playStopButton addTarget:self action:@selector(playOrStop:) forControlEvents:(UIControlEventTouchUpInside)];
    [bottomBar addSubview:_playStopButton];
    
    CGFloat mixButtonWidth = 36;
    _mixButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 15 - mixButtonWidth, bottomHeight/2.0-mixButtonWidth/2.0, 40, mixButtonWidth)];
    _mixButton.backgroundColor = [UIColor clearColor];
    _mixButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [_mixButton setTitle:@"混音" forState:(UIControlStateNormal)];
    [_mixButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [_mixButton addTarget:self action:@selector(startMix) forControlEvents:(UIControlEventTouchUpInside)];
    [bottomBar addSubview:_mixButton];
    
    _showMixedButton = [[UIButton alloc] initWithFrame:CGRectMake(15, bottomHeight/2.0-mixButtonWidth/2.0, 40, mixButtonWidth)];
    _showMixedButton.backgroundColor = [UIColor clearColor];
    _showMixedButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [_showMixedButton setTitle:@"已录" forState:(UIControlStateNormal)];
    [_showMixedButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [_showMixedButton addTarget:self action:@selector(showAllMixAudios) forControlEvents:(UIControlEventTouchUpInside)];
    [bottomBar addSubview:_showMixedButton];
}

#pragma mark - record

-(void)playOrStop:(UIButton *)button{
    if (_player.playing) {
        [_player stop];
        [_recorder stop];
        [_recordWriter close];
    }else{
        [_player playLocalFile:_curAccompany.filePath];
        
        [_recorder start];
    }
    
    if (_player.playing) {
        [button setImage:[UIImage imageNamed:@"stop"] forState:(UIControlStateNormal)];
    }else{
        [button setImage:[UIImage imageNamed:@"play"] forState:(UIControlStateNormal)];
    }
}

- (IBAction)selectMusic:(id)sender {
    
    TFMusicListViewController *musicListVC = [[TFMusicListViewController alloc] init];
    musicListVC.rootDirectory = @"accompanies";
    
    musicListVC.selectMusicConpletionHandler = ^(TFMediaData *music){
        _curAccompany = music;
        self.title = _curAccompany.filename;
        _musicCover.image = _curAccompany.coverImage;
    };
    [self.navigationController pushViewController:musicListVC animated:YES];
}

-(NSString *)recordHome{
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documentDir stringByAppendingFormat:@"/sing_records"];
}

-(void)setupAudioComponents{
    _player = [[TFAudioUnitPlayer alloc] init];
    _recorder = [[TFAudioRecorder alloc]init];

    NSString *recordPath = [[self recordHome] stringByAppendingFormat:@"/%lld",(UInt64)[[NSDate date] timeIntervalSince1970]];
    
    _recordWriter = [[TFAudioFileWriter alloc] init];
    _recordWriter.filePath = recordPath;
    _recordWriter.fileType = kAudioFileCAFType;
    [_recorder addTarget:_recordWriter];
}

#pragma mark - mix

-(NSString *)mixHome{
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documentDir stringByAppendingFormat:@"/sing_mixeds"];
}

-(void)startMix{

    if ([self setupMixer]) {
        [_mixer start];
    }
}

-(void)showAllMixAudios{
    
    TFMediaListViewController *mediaListVC = [[TFMediaListViewController alloc] init];
    mediaListVC.mediaDir = [self mixHome]; //删掉最后一节，得到文件夹
    
    mediaListVC.selectHandler = ^(TFMediaData *mediaData){
        NSLog(@"select audio file %@",mediaData.filename);
        
        //play audio file
        if ([mediaData.fileExtension isEqualToString:@"caf"]) {
            if (!_mixedAudioPlayer) {
                _mixedAudioPlayer = [[TFAudioUnitPlayer alloc] init];
            }
            NSLog(@"play mixed");
            [_mixedAudioPlayer playLocalFile:mediaData.filePath];
        }
    };
    
    mediaListVC.disappearHandler = ^(){
        [_mixedAudioPlayer stop];
    };
    
    [self.navigationController pushViewController:mediaListVC animated:YES];
}

-(BOOL)setupMixer{
    //一个混音组件+2个文件读取器,一个伴奏文件一个录音文件
    if (!_mixer) {
        _mixer = [[TFAudioMixer alloc] init];
        _mixer.sourceType = TFAudioMixerSourceTypeTwoPull;
        
        _mixedAudioWriter = [[TFAudioFileWriter alloc] init];
        _mixedAudioWriter.fileType = kAudioFileCAFType;
        [_mixer addTarget:_mixedAudioWriter];
    }
    
    NSString *recordPath = _recordWriter.filePath;
    if (_curAccompany.filePath == nil || recordPath == nil) {
        return NO;
    }
    
    TFAudioFileReader *fileReader1 = [[TFAudioFileReader alloc] init];
    fileReader1.filePath = _curAccompany.filePath;
    _mixer.pullAudioSource = fileReader1;
    
    TFAudioFileReader *fileReader2 = [[TFAudioFileReader alloc] init];
    fileReader2.filePath = recordPath;
    _mixer.pullAudioSource2 = fileReader2;
    
    //new file
    _mixedAudioPath = [[self mixHome] stringByAppendingFormat:@"/%lld",(UInt64)[[NSDate date] timeIntervalSince1970]];
    _mixedAudioWriter.filePath = _mixedAudioPath;
    
    return YES;
}

@end
