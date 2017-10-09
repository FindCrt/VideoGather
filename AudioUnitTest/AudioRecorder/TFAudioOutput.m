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
}

@end

@implementation TFAudioOutput

-(instancetype)init{
    if (self = [super init]) {
        _targets = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(NSArray *)targets{
    return [_targets copy];
}

-(void)addTarget:(id<TFAudioInput>)target{
    [_targets addObject:target];
    
    if (_audioDesc.mSampleRate != 0) {
        [target setAudioDesc:_audioDesc];
    }
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    _audioDesc = audioDesc;
    
    for (id<TFAudioInput> target in _targets) {
        [target setAudioDesc:_audioDesc];
    }
}

-(void)transportAudioBuffersToNext{
    for (id<TFAudioInput>target in _targets) {
        [target receiveNewAudioBuffers:self.bufferData];
    }
    
    if (self.completedHandler) {
        self.completedHandler();
    }
}

@end
