//
//  TFAudioConvertor.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioConvertor.h"

@interface TFAudioConvertor (){
    AudioConverterRef _audioConverter;
    
    AudioStreamBasicDescription _outputDesc;
}

@end

@implementation TFAudioConvertor

-(instancetype)init{
    if (self = [super init]) {
        
    }
    
    return self;
}

-(void)setOutputFormat:(AudioFormatID)outputFormat{
    _outputDesc.mFormatID = outputFormat;
    
}

-(AudioFormatID)outputFormat{
    return _outputDesc.mFormatID;
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    [super setAudioDesc:audioDesc];
    
    //先按s16样式来配置
    _outputDesc.mSampleRate = audioDesc.mSampleRate;
    _outputDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    _outputDesc.mFramesPerPacket = 1;
    _outputDesc.mChannelsPerFrame = audioDesc.mChannelsPerFrame;
    _outputDesc.mBitsPerChannel =
    _outputDesc.mBytesPerPacket = 
    
    [self setupAudioConverter];
}

-(void)setupAudioConverter{
    AudioStreamBasicDescription sourceDesc = self.audioDesc;
    OSStatus status = AudioConverterNew(&sourceDesc, &_outputDesc, &_audioConverter);
    
    TFCheckStatus(status, @"create audio convert failed!");
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData{
    
    
    AudioConverterFillComplexBuffer(<#AudioConverterRef  _Nonnull inAudioConverter#>, <#AudioConverterComplexInputDataProc  _Nonnull inInputDataProc#>, <#void * _Nullable inInputDataProcUserData#>, <#UInt32 * _Nonnull ioOutputDataPacketSize#>, <#AudioBufferList * _Nonnull outOutputData#>, <#AudioStreamPacketDescription * _Nullable outPacketDescription#>)
}


@end
