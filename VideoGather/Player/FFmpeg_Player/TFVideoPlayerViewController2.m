//
//  TFVideoPlayerViewController2.m
//  VideoGather
//
//  Created by shiwei on 17/9/5.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFVideoPlayerViewController2.h"
#import <libavformat/avformat.h>

@interface TFVideoPlayerViewController2 ()

@end

@implementation TFVideoPlayerViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    
    av_register_all();
}

@end
