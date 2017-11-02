//
//  TFMusicListViewController.m
//  VideoGather
//
//  Created by shiwei on 17/11/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFMusicListViewController.h"
#import "TFMediaDataAnalyzer.h"
#import "TFAudioUnitPlayer.h"
#import "NSString+convience.h"

#define TFPlayButtonTag     100
#define TFSelectButtonTag   1000

@interface TFMusicListViewController (){
    NSMutableArray *_musicList;
    TFAudioUnitPlayer *audioPlayer;
}

@end

@implementation TFMusicListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _musicList = [[NSMutableArray alloc] init];
    NSArray *items = [[NSBundle mainBundle] pathsForResourcesOfType:@"mp3" inDirectory:nil];
    for (NSString *itemPath in items) {
        [_musicList addObject:[TFMediaDataAnalyzer mediaDataForItemAt:itemPath]];
    }
    
    audioPlayer = [[TFAudioUnitPlayer alloc] init];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [audioPlayer stop];
}

-(void)playMusic:(UIButton *)button{
    NSInteger index = button.tag - TFPlayButtonTag;
    
    TFMediaData *mediaData = _musicList[index];
    
    
    [audioPlayer playLocalFile:mediaData.filePath];
}

-(void)selectMusic:(UIButton *)button{
    NSInteger index = button.tag - TFPlayButtonTag;
    
    TFMediaData *mediaData = _musicList[index];
    
    if (_selectMusicConpletionHandler) {
        _selectMusicConpletionHandler(mediaData);
    }
}

-(void)dealloc{
    NSLog(@"TFMusicListViewController dealloc");
}

#pragma mark - tableview delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _musicList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"musicCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:@"musicCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIButton *play = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width - 70, 17, 50, 30)];
        play.tag = indexPath.row + TFPlayButtonTag;
        play.backgroundColor = [UIColor orangeColor];
        [play setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [play setTitle:@"play" forState:(UIControlStateNormal)];
        [play addTarget:self action:@selector(playMusic:) forControlEvents:(UIControlEventTouchUpInside)];
        play.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin ;
        [cell addSubview:play];
        
        UIButton *select = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width - 150, 17, 70, 30)];
        select.tag = indexPath.row + TFSelectButtonTag;
        select.backgroundColor = [UIColor brownColor];
        [select setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [select setTitle:@"select" forState:(UIControlStateNormal)];
        [select addTarget:self action:@selector(selectMusic:) forControlEvents:(UIControlEventTouchUpInside)];
        select.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin ;
        [cell addSubview:select];
    }
    
    TFMediaData *mediaData = _musicList[indexPath.row];
    cell.textLabel.text = mediaData.filename;
    cell.detailTextLabel.text = [NSString timeTextFromSeconds:mediaData.duration];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

@end
