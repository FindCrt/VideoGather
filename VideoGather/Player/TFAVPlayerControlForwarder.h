//
//  TFAVPlayerControlForwarder.h
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

//forward commands from player control view to AVPlayer object.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TFVideoControlView.h"

@interface TFAVPlayerControlForwarder : NSObject<TFVideoControlViewControlDelegate>

@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic, weak) TFVideoControlView *controlView;

@end

