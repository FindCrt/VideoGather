//
//  TFAudioOutput.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioInput.h"
#import "TFAudioBufferData.h"


typedef void(^TFAudioOutputCompletedHandler)();

@interface TFAudioOutput : NSObject

@property (nonatomic, assign) TFAudioBufferData *bufferData;

@property (nonatomic, assign) AudioStreamBasicDescription audioDesc;

@property (nonatomic, copy, readonly) NSArray *targets;

//输入和输出不同时需要重载，比如格式转换组件
-(AudioStreamBasicDescription)outputAudioDescWithInputDesc:(AudioStreamBasicDescription)audioDesc;

//当前环节处理结束，调用此方法把数据传输到下一个环节，数据必须放在bufferData里
-(void)transportAudioBuffersToNext;

@property (nonatomic, copy) TFAudioOutputCompletedHandler completedHandler;

-(void)addTarget:(id<TFAudioInput>)target;

-(void)addTarget:(id<TFAudioInput>)target inputIndex:(NSInteger)inputIndex;

@end
