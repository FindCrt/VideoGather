//
//  TFAudioInput.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioBufferData.h"
#import "TFStatusChecker.h"

@protocol TFAudioInput <NSObject>

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc;
-(AudioStreamBasicDescription)audioDesc;

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData;

@optional

//inputIndex是在target里，当前类作为第几个输入源，用于多个输入源的TFAudioInput，区分不同输入源，比如混音
-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData inputIndex:(NSInteger)inputIndex;

@end
