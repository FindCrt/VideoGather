//
//  TFVideoExchanger.m
//  VideoGather
//
//  Created by shiwei on 17/9/6.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFVideoExchanger.h"
#import "VRVideoEncoder.h"
#import <AVFoundation/AVFoundation.h>

@interface TFVideoExchanger (){
    AVPlayer *_player;
}

@end

@implementation TFVideoExchanger

-(void)setFilePath:(NSString *)filePath{
    _filePath = filePath;
    
    _player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:_filePath]];
    
}

-(void)startExchange{
    
}

@end
