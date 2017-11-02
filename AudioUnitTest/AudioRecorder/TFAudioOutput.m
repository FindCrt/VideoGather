//
//  TFAudioOutput.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioOutput.h"

@interface TFAudioOutput (){
    NSMutableArray *_targets;
    
    NSMutableDictionary *_targetInputIndex;
}

@end

@implementation TFAudioOutput

-(instancetype)init{
    if (self = [super init]) {
        _targets = [[NSMutableArray alloc] init];
        _targetInputIndex = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(NSArray *)targets{
    return [_targets copy];
}

-(void)addTarget:(id<TFAudioInput>)target{
    [self addTarget:target inputIndex:0];
}

-(void)addTarget:(id<TFAudioInput>)target inputIndex:(NSInteger)inputIndex{
    [_targets addObject:target];
    
    if (_audioDesc.mSampleRate != 0) {
        [target setAudioDesc:_audioDesc];
    }
    
    [_targetInputIndex setObject:@(inputIndex) forKey:[target description]];
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    _audioDesc = audioDesc;
    
    
    AudioStreamBasicDescription outputDesc = [self outputAudioDescWithInputDesc:audioDesc];
    for (id<TFAudioInput> target in _targets) {
        [target setAudioDesc:outputDesc];
    }
}

-(AudioStreamBasicDescription)outputAudioDescWithInputDesc:(AudioStreamBasicDescription)audioDesc{
    return audioDesc; //默认输出与输入一样的格式
}

-(void)transportAudioBuffersToNext{
    for (id<TFAudioInput>target in _targets) {
        
        if ([target respondsToSelector:@selector(receiveNewAudioBuffers:inputIndex:)]) {
            
            NSInteger inputIndex = [[_targetInputIndex objectForKey:[target description]] integerValue];
            [target receiveNewAudioBuffers:self.bufferData inputIndex:inputIndex];
        }else{
            [target receiveNewAudioBuffers:self.bufferData];
        }
    }
    
    if (self.completedHandler) {
        self.completedHandler();
    }
}

@end
