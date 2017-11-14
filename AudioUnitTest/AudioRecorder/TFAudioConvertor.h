//
//  TFAudioConvertor.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioInput.h"
#import "TFAudioOutput.h"


@interface TFAudioConvertor : TFAudioOutput<TFAudioInput>

/** 希望输出的格式，smaleRate设为0，则采取跟输入一样的sampleRate, 声道数也一样 */
@property (nonatomic, assign) AudioStreamBasicDescription outputDesc;


@end
