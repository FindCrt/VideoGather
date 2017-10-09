//
//  TFAudioConvertor.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioConvertor.h"

@interface TFAudioConvertor (){
    
}

@end

@implementation TFAudioConvertor

-(instancetype)init{
    if (self = [super init]) {
        
    }
    
    return self;
}

-(void)receiveNewAudioBuffers:(AudioBufferList *)bufferList{
    self.bufferList = bufferList;
}

-(void)startProcessing{
    
}

@end
