//
//  TFAudioUnitRecordViewController.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioUnitRecordViewController.h"
#import "TFAudioRecorder.h"
#import "TFMediaListViewController.h"
#import "TFMediaDataAnalyzer.h"
#import "TFAudioFileWriter.h"
#import "TFAudioConvertor.h"
#import "TFAACFileWriter.h"
#import "TFAudioUnitPlayer.h"

#define TFUseSystemConverter    1       //pcm+ExtAudioFile,ExtAudioFile involve converter of pcm to aac.
#define WriterCount             1

#define AudioTestType   2  // 1: pcm+caf 2: aac+extAudioFile(m4a) 3: pcm+convertor+audioFile(adts) 4. multi recorders

@interface TFAudioUnitRecordViewController (){
    NSString *_curRecordPath;
    
    TFAudioRecorder *_recorder;
    
    TFAACFileWriter *_aacFileWriter;
    TFAudioFileWriter *_pcmFileWriter;
    TFAudioFileWriter *_systemAACFileWriter;
    
    NSMutableArray<TFAudioRecorder *> *_multiRecorders;
#if TFUseSystemConverter
    NSMutableArray *_systemConvertWriter;
#else
    NSMutableArray *_selfConvertWriter;
#endif
    
    TFAudioUnitPlayer *_audioPlayer;
}

@property (nonatomic, copy) NSString *recordHome;

@end

@implementation TFAudioUnitRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self setupPerformancePipline];  //性能测试
    [self setupRecorder];
}

-(void)setupRecorder{
    _recorder = [[TFAudioRecorder alloc] init];
    
#if AudioTestType == 1
    //pcm+caf
    [self setupPcmCafPipline];
    
#elif AudioTestType == 2
    
    [self setupAACSystemConvertorPipline];
    
    
#elif AudioTestType == 3
    
    //aac+adts
    [self setupAacAdtsPipline];
    
#elif AudioTestType == 4
    
    //performance test: compare pcm+extAudioFile-->aac+m4a with pcm+aac encoder+AudioFile--->aac+adts;
    [self setupPerformancePipline];
    
#endif
}

-(NSString *)recordHome{
    if (!_recordHome) {
        _recordHome = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"audioURecords"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_recordHome]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_recordHome withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }

    return _recordHome;
}


-(NSString *)nextRecordPath{
    NSString *name = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
    
    _curRecordPath = [self.recordHome stringByAppendingPathComponent:name];
    
    return _curRecordPath;
}

- (IBAction)showRecordList:(id)sender {
    TFMediaListViewController *mediaListVC = [[TFMediaListViewController alloc] init];
    mediaListVC.mediaDir = self.recordHome;
    
    mediaListVC.selectHandler = ^(TFMediaData *mediaData){
        NSLog(@"select audio file %@",mediaData.filename);
        
        //play audio file
        if (mediaData.isAudio) {
            if (!_audioPlayer) {
                _audioPlayer = [[TFAudioUnitPlayer alloc] init];
            }
            
            [_audioPlayer playLocalFile:mediaData.filePath];
        }
    };
    
    mediaListVC.disappearHandler = ^(){
        [_audioPlayer stop];
    };
    
    [self.navigationController pushViewController:mediaListVC animated:YES];
}

- (IBAction)startOrStopRecord:(UIButton *)sender {
    
#if AudioTestType == 1
    
    //pcm+caf
    [self pcmCafStartOrStop:sender];
    
#elif AudioTestType == 2
    //aac+ExtAudioFile(m4a)
    [self AACSystemConvertorStartOrStop:sender];
    
#elif AudioTestType == 3
    
    //aac+adts
    [self aacAdtsStartOrStop:sender];
    
#elif AudioTestType == 4
    //performance test: compare pcm+extAudioFile-->aac+m4a with pcm+aac encoder+AudioFile--->aac+adts;
    [self performanceTestSartOrStop:sender];
#endif
}

#pragma mark - write aac+adts

-(void)setupAacAdtsPipline{
    _recorder = [[TFAudioRecorder alloc] init];
    
    TFAudioConvertor *converter = [[TFAudioConvertor alloc] init];
    converter.outputFormat = kAudioFormatMPEG4AAC;
    [_recorder addTarget:converter];
    
    _aacFileWriter = [[TFAACFileWriter alloc] init];
    _aacFileWriter.filePath = [self nextRecordPath];
    [converter addTarget:_aacFileWriter];

}

-(void)aacAdtsStartOrStop:(UIButton *)button{
    if (_recorder.recording) {
        [_recorder stop];
        [_aacFileWriter close];
    }else{
        [_recorder start];
    }
    
    if (_recorder.recording) {
        [button setTitle:@"stop" forState:(UIControlStateNormal)];
    }else{
        [button setTitle:@"start" forState:(UIControlStateNormal)];
    }
}

#pragma mark - write pcm+caf

-(void)setupPcmCafPipline{
    _recorder = [[TFAudioRecorder alloc] init];
    
    _pcmFileWriter = [[TFAudioFileWriter alloc] init];
    _pcmFileWriter.filePath = [self nextRecordPath];
    _pcmFileWriter.fileType = kAudioFileCAFType;
    [_recorder addTarget:_pcmFileWriter];
}

-(void)pcmCafStartOrStop:(UIButton *)button{
    if (_recorder.recording) {
        [_recorder stop];
        [_pcmFileWriter close];
    }else{
        [_recorder start];
    }
    
    if (_recorder.recording) {
        [button setTitle:@"stop" forState:(UIControlStateNormal)];
    }else{
        [button setTitle:@"start" forState:(UIControlStateNormal)];
    }
}

#pragma mark - write aac+ExtAudiFile+m4a

-(void)setupAACSystemConvertorPipline{
    _recorder = [[TFAudioRecorder alloc] init];
    
    _systemAACFileWriter = [[TFAudioFileWriter alloc] init];
    _systemAACFileWriter.filePath = [self nextRecordPath];
    _systemAACFileWriter.fileType = kAudioFileM4AType;
    [_recorder addTarget:_systemAACFileWriter];
}

-(void)AACSystemConvertorStartOrStop:(UIButton *)button{
    if (_recorder.recording) {
        [_recorder stop];
        [_systemAACFileWriter close];
    }else{
        [_recorder start];
    }
    
    if (_recorder.recording) {
        [button setTitle:@"stop" forState:(UIControlStateNormal)];
    }else{
        [button setTitle:@"start" forState:(UIControlStateNormal)];
    }
}


#pragma mark - performance test

-(void)setupPerformancePipline{
    _multiRecorders = [[NSMutableArray alloc] init];
    for (int i = 0; i<WriterCount; i++) {
        TFAudioRecorder *recorder = [[TFAudioRecorder alloc] init];
        [_multiRecorders addObject:recorder];
    }
    
    [self setupPerformanceWriters];
}

-(void)setupPerformanceWriters{
    
#if TFUseSystemConverter
    _systemConvertWriter = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<WriterCount; i++) {
        TFAudioFileWriter *writer = [[TFAudioFileWriter alloc]init];
        writer.filePath = [[NSString alloc] initWithFormat:@"%@_%d",[self nextRecordPath],i];
        writer.fileType = kAudioFileCAFType;
        [_recorder addTarget:writer];
        
        [_systemConvertWriter addObject:writer];
    }
    
#else
    
    _selfConvertWriter = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<WriterCount; i++) {
        
        TFAudioRecorder *recorder = _multiRecorders[i];
        
        TFAudioConvertor *converter = [[TFAudioConvertor alloc] init];
        converter.outputFormat = kAudioFormatMPEG4AAC;
        [recorder addTarget:converter];
        
        TFAACFileWriter *writer = [[TFAACFileWriter alloc]init];
        writer.filePath = [[NSString alloc] initWithFormat:@"%@_aac_%d",[self nextRecordPath],i];
        [converter addTarget:writer];
        
        [_selfConvertWriter addObject:writer];
    }
    
#endif
}

-(void)performanceTestSartOrStop:(UIButton *)button{
    if (_multiRecorders.firstObject.recording) {

        for (TFAudioRecorder *recorder in _multiRecorders) {
            [recorder stop];
        }
        
#if TFUseSystemConverter
        for (TFAudioFileWriter *writer in _systemConvertWriter) {
            [writer close];
        }
#else
        for (TFAACFileWriter *writer in _selfConvertWriter) {
            [writer close];
        }
#endif
        
    }else{ //start
        for (TFAudioRecorder *recorder in _multiRecorders) {
            [recorder start];
        }
    }
    
    if (_multiRecorders.firstObject.recording) {
        [button setTitle:@"stop" forState:(UIControlStateNormal)];
    }else{
        [button setTitle:@"start" forState:(UIControlStateNormal)];
    }
}

@end
