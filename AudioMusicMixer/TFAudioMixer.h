//
//  TFAudioMixer.h
//  VideoGather
//
//  Created by shiwei on 17/11/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioOutput.h"
#import "TFAudioReader.h"

/* 1: 音频可以是数据流，是push模式，不断向外界推送；也可以是静态的，如文件，需要多少读取多少，是pull模式
 * 2: 对于混音的两方就可能出现3种情况：
 *      (1)两个都是流的时候，需要建缓冲区来做两条流的匹配，因为进度可能不一致。进度需要自身来控制，通过缓冲区把push转成pull
 *      (2)一个流一个静态的时候，使用流作为进度，不需要缓冲区也不需要自己控制进度
 *      (3)两个静态数据源，自己控制进度，但不需要缓冲区
 */

typedef NS_ENUM(NSInteger, TFAudioMixerSourceType){
    TFAudioMixerSourceTypeOnePushOnePull,
    TFAudioMixerSourceTypeTwoPush,
    TFAudioMixerSourceTypeTwoPull
};

@interface TFAudioMixer : TFAudioOutput<TFAudioInput>

@property (nonatomic, strong) id<TFAudioReader> pullAudioSource;

@property (nonatomic, assign) TFAudioMixerSourceType sourceType;

@end
