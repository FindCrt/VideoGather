//
//  TFAudioRecorder.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioOutput.h"

typedef NS_ENUM(NSInteger, TFOutputAudioFileType){
    TFOutputAudioFileTypeCAF,
    TFOutputAudioFileTypeWAV,
    TFOutputAudioFileTypeM4A
};

@interface TFAudioRecorder : TFAudioOutput

@property (nonatomic, assign) BOOL recording;

-(void)start;

-(void)stop;

@end
