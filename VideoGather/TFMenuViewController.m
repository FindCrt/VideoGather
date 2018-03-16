//
//  TFMenuViewController.m
//  VideoGather
//
//  Created by shiwei on 17/8/31.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFMenuViewController.h"
#import "TFCameraViewController.h"
#import "TFVideoPlayerViewController.h"
#import "TFVideoGatherViewController.h"

@interface TFMenuViewController (){
    NSArray *_funcNameList;
    NSArray *_funcVCList;
}

@end

@implementation TFMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _funcNameList = @[@"video record",@"video play", @"video transfer"];
    //_funcVCList = @[@"TFCameraViewController",@"TFVideoPlayerViewController"];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _funcNameList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = _funcNameList[indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        
        TFCameraViewController *cameraVC = [[TFCameraViewController alloc] init];
        [self.navigationController pushViewController:cameraVC animated:YES];
        
    }else if (indexPath.row == 1){
        
        TFVideoPlayerViewController *videoPlayVC = [[TFVideoPlayerViewController alloc] init];
        
        NSURL *netURL = [NSURL URLWithString:@"http://video.devimg.com/infoflow/M00/00/61/wKgJF1qPhLiAZXUWAAOXwPxUiIU822.mp4"];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"际信测试视频" ofType:@"mp4"];
//        videoPlayVC.videoURL = [NSURL fileURLWithPath:path];
        videoPlayVC.videoURL = netURL;
        [self.navigationController pushViewController:videoPlayVC animated:YES];
        
    }else if (indexPath.row == 2){
        
        TFVideoGatherViewController *videoGatherVC = [[TFVideoGatherViewController alloc] init];
        [self.navigationController pushViewController:videoGatherVC animated:YES];
        
    }
}

@end
