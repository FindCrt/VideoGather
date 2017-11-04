//
//  ViewController.m
//  AudioMusicMixer
//
//  Created by shiwei on 17/11/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "ViewController.h"
#import "TFMusicListViewController.h"
#import "TFAudioRecorder.h"
#import "TFAudioMixer.h"
#import "TFAudioFileReader.h"
#import "TFAudioFileWriter.h"
#import "TFMediaListViewController.h"
#import "TFAudioUnitPlayer.h"

#define SimultaneousRecordAndMix    1
#define MixPcmData  1

@interface ViewController (){
    TFMediaData *_selectedMusic;
    
    TFAudioRecorder *_recorder;
    TFAudioFileReader *_fileReader;
    TFAudioMixer *_mixer;
    TFAudioFileWriter *_writer;
    
    NSString *_curRecordPath;
    TFAudioUnitPlayer *_audioPlayer;
}
@property (weak, nonatomic) IBOutlet UILabel *musicLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@property (nonatomic, copy) NSString *recordHome;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"selectMusic"]) {
        TFMusicListViewController *destVC = segue.destinationViewController;
        destVC.selectMusicConpletionHandler = ^(TFMediaData *music){
            _selectedMusic = music;
            _musicLabel.text = music.filename;
            
        };
    }
}

- (IBAction)recordOrStop:(UIButton *)button {
    //TODO:先获取麦克风权限
    
    if (_recorder.recording) {
        
        [_recorder stop];
        [_writer close];
        
        [button setTitle:@"record" forState:(UIControlStateNormal)];
        
    }else{
        _mixer = [[TFAudioMixer alloc] init];
        
        _recorder = [[TFAudioRecorder alloc] init];
        [_recorder addTarget:_mixer inputIndex:0];
        
        _fileReader = [[TFAudioFileReader alloc] init];
        _fileReader.filePath = _selectedMusic.filePath;
        _mixer.pullAudioSource = _fileReader;
        
        _writer = [[TFAudioFileWriter alloc] init];
        _writer.filePath = [self nextRecordPath];
        _writer.fileType = kAudioFileCAFType;
        [_mixer addTarget:_writer];
        
        [_recorder start];
        
        [button setTitle:@"stop" forState:(UIControlStateNormal)];
    }
    
}

-(NSString *)recordHome{
    if (!_recordHome) {
        _recordHome = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"audioMusicMix"];
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

- (IBAction)showMixedList:(id)sender {
    TFMediaListViewController *mediaListVC = [[TFMediaListViewController alloc] init];
    mediaListVC.mediaDir = self.recordHome;
    
    mediaListVC.selectHandler = ^(TFMediaData *mediaData){
        NSLog(@"select audio file %@",mediaData.filename);
        
        //play audio file
        if ([mediaData.fileExtension isEqualToString:@"caf"]) {
            if (!_audioPlayer) {
                _audioPlayer = [[TFAudioUnitPlayer alloc] init];
            }
            
            [_audioPlayer playLocalFile:mediaData.filePath];
        }
    };
    
    [self.navigationController pushViewController:mediaListVC animated:YES];
}


@end
