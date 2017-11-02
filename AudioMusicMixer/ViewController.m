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

#define SimultaneousRecordAndMix    1
#define MixPcmData  1

@interface ViewController (){
    TFMediaData *_selectedMusic;
    
    TFAudioRecorder *_recorder;
    TFAudioMixer *_mixer;
}
@property (weak, nonatomic) IBOutlet UILabel *musicLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;

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

- (IBAction)recordOrStop:(id)sender {
    _mixer = [[TFAudioMixer alloc] init];
    
    _recorder = [[TFAudioRecorder alloc] init];
    [_recorder addTarget:_mixer inputIndex:0];
    
    
}

@end
