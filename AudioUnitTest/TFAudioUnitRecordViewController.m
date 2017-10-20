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

@interface TFAudioUnitRecordViewController (){
    NSString *_curRecordPath;
    
    TFAudioRecorder *_recorder;
    
    TFAACFileWriter *_fileWriter;
}

@property (nonatomic, copy) NSString *recordHome;

@end

@implementation TFAudioUnitRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupRecorder];
}

-(void)setupRecorder{
    _recorder = [[TFAudioRecorder alloc] init];
    
    TFAudioConvertor *converter = [[TFAudioConvertor alloc] init];
    converter.outputFormat = kAudioFormatMPEG4AAC;
    [_recorder addTarget:converter];
    
    _fileWriter = [[TFAACFileWriter alloc] init];
    _fileWriter.filePath = [self nextRecordPath];
    [converter addTarget:_fileWriter];
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
    if (_recorder.recording) {
        
        [_recorder stop];
        [_fileWriter close];
        
    }else{          //start
        
        [_recorder startRecordToPath:[self nextRecordPath]];
        _fileWriter.filePath = _curRecordPath;
    }
    
    if (_recorder.recording) {
        [sender setTitle:@"stop" forState:(UIControlStateNormal)];
    }else{
        [sender setTitle:@"start" forState:(UIControlStateNormal)];
    }
    
}

@end
