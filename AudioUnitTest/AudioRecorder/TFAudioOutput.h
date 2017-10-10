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

-(void)transportAudioBuffersToNext;

@property (nonatomic, copy) TFAudioOutputCompletedHandler completedHandler;

-(void)addTarget:(id<TFAudioInput>)target;


@end
