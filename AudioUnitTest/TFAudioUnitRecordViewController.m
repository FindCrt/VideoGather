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

#define TFUseSystemConverter    0
#define WriterCount             10

@interface TFAudioUnitRecordViewController (){
    NSString *_curRecordPath;
    
    TFAudioRecorder *_recorder;
    
    TFAACFileWriter *_aacFileWriter;
    TFAudioFileWriter *_pcmFileWriter;
    
    NSMutableArray<TFAudioRecorder *> *_multiRecorders;
#if TFUseSystemConverter
    NSMutableArray *_systemConvertWriter;
#else
    NSMutableArray *_selfConvertWriter;
#endif
}

@property (nonatomic, copy) NSString *recordHome;

@end

@implementation TFAudioUnitRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupRecorder];
}

-(void)setupRecorder{
//    _recorder = [[TFAudioRecorder alloc] init];
    
//    TFAudioConvertor *converter = [[TFAudioConvertor alloc] init];
//    converter.outputFormat = kAudioFormatMPEG4AAC;
//    [_recorder addTarget:converter];
//    
//    _aacFileWriter = [[TFAACFileWriter alloc] init];
//    _aacFileWriter.filePath = [self nextRecordPath];
//    [converter addTarget:_aacFileWriter];
    
//    _pcmFileWriter = [[TFAudioFileWriter alloc] init];
//    _pcmFileWriter.filePath = [self nextRecordPath];
//    _pcmFileWriter.fileType = kAudioFileM4AType;
//    [_recorder addTarget:_pcmFileWriter];
    
    _multiRecorders = [[NSMutableArray alloc] init];
    for (int i = 0; i<WriterCount; i++) {
        TFAudioRecorder *recorder = [[TFAudioRecorder alloc] init];
        [_multiRecorders addObject:recorder];
    }
    [self setupWriters];
}

-(void)setupWriters{
    
#if TFUseSystemConverter
    _systemConvertWriter = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<WriterCount; i++) {
        TFAudioFileWriter *writer = [[TFAudioFileWriter alloc]init];
        writer.filePath = [[NSString alloc] initWithFormat:@"%@_%d",[self nextRecordPath],i];
        writer.fileType = kAudioFileM4AType;
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
    };
    
    [self.navigationController pushViewController:mediaListVC animated:YES];
}

- (IBAction)startOrStopRecord:(UIButton *)sender {
    if (_multiRecorders.firstObject.recording) {
        
//        [_recorder stop];
        
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
        
//        [_recorder start];
        for (TFAudioRecorder *recorder in _multiRecorders) {
            [recorder start];
        }
    }
    
    if (_multiRecorders.firstObject.recording) {
        [sender setTitle:@"stop" forState:(UIControlStateNormal)];
    }else{
        [sender setTitle:@"start" forState:(UIControlStateNormal)];
    }
    
}

@end
