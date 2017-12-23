//
//  TFAudioRecorder.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>


#define kOutputBus 0
#define kInputBus 1
#define  kSampleRate 44100.0
#define kFramesPerPacket 1
#define kChannelsPerFrame 2
#define kBitsPerChannel 32  //s16
//#define BUFFER_SIZE 1024

typedef NS_ENUM(NSInteger, TFAudioEncodeType){
    TFAudioEncodeTypePCM,
    TFAudioEncodeTypeAAC
};

@interface TFAudioRecorder (){
    AudioFileTypeID fileTypeID;
    AudioComponentInstance audioUnit;
    
    struct AudioBuffer audioBuffer;
    
    ExtAudioFileRef mAudioFileRef;
    
    TFAudioEncodeType encodeType;
    
    NSMutableArray<id > *_targets;
}

@end

@implementation TFAudioRecorder

-(instancetype)init{
    if (self = [super init]) {
        encodeType = TFAudioEncodeTypePCM;
    }
    
    return self;
}

-(void)start{
    OSStatus status;
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output; // we want to ouput
    desc.componentSubType = kAudioUnitSubType_RemoteIO; // we want in and ouput
    desc.componentFlags = 0; // must be zero
    desc.componentFlagsMask = 0; // must be zero
    desc.componentManufacturer = kAudioUnitManufacturer_Apple; // select provider
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    
    TFCheckStatus(status, @"AudioComponentInstanceNew")
    
    
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,kAudioOutputUnitProperty_EnableIO, // use io
                                  kAudioUnitScope_Input, // 开启输入
                                  kInputBus, //element1是硬件到APP的组件
                                  &flag, // 开启，输出YES
                                  sizeof(flag));
    TFCheckStatus(status, @"enable input io")


    AudioStreamBasicDescription audioFormat;
    audioFormat = [self audioDescForType:encodeType];
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    //-10868 kAudioUnitErr_FormatNotSupported
    TFCheckStatus(status, @"set record output format")
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    TFCheckStatus(status, @"SetInputCallback")

    flag = 0;
    status = AudioUnitSetProperty(audioUnit,kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    TFCheckStatus(status, @"ShouldAllocateBuffer")

    status = AudioUnitInitialize(audioUnit);
    TFCheckStatus(status, @"AudioUnitInitialize")
    
    self.audioDesc = audioFormat;  //tanspost to next unit
    
    //audio session
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setPreferredSampleRate:44100 error:&error];
    TFCheckError(error, @"setPreferredSampleRate")
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionMixWithOthers
                   error:&error];
    TFCheckError(error, @"setCategory")
    [session setActive:YES error:&error];
    TFCheckError(error, @"active audio session")
    
    AudioOutputUnitStart(audioUnit);
    
    _recording = YES;
    
    NSLog(@"recorder started!!");
}

-(void)stop{
    AudioOutputUnitStop(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    
    ExtAudioFileDispose(mAudioFileRef);
    
    _recording = NO;
}

-(AudioStreamBasicDescription)audioDescForType:(TFAudioEncodeType)type{
    
    AudioStreamBasicDescription audioFmt;
    
    if (type == TFAudioEncodeTypePCM) {
//        audioFmt.mSampleRate = kSampleRate;
//        audioFmt.mFormatID = kAudioFormatLinearPCM;
//        audioFmt.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
//        audioFmt.mFramesPerPacket = kFramesPerPacket;
//        audioFmt.mChannelsPerFrame = kChannelsPerFrame;
//        audioFmt.mBitsPerChannel = kBitsPerChannel;
//        audioFmt.mBytesPerPacket = kBitsPerChannel * kChannelsPerFrame * kFramesPerPacket / 8;
//        audioFmt.mBytesPerFrame = kBitsPerChannel * kChannelsPerFrame / 8;
//        audioFmt.mReserved = 0;
        
        FillOutASBDForLPCM (audioFmt,kSampleRate,kChannelsPerFrame,kBitsPerChannel,kBitsPerChannel,true,false,false);
        
        //FillOutASBDForLPCM
        
    }else if(type == TFAudioEncodeTypeAAC){
        
        audioFmt.mSampleRate         = kSampleRate;
        audioFmt.mFormatID           = kAudioFormatMPEG4AAC;
        audioFmt.mFormatFlags        = kMPEG4Object_AAC_Main;
        audioFmt.mChannelsPerFrame   = kChannelsPerFrame;
        audioFmt.mBytesPerPacket     = 0;
        audioFmt.mBytesPerFrame      = 0;
        audioFmt.mFramesPerPacket    = 1024;
        audioFmt.mBitsPerChannel     = 0;
        audioFmt.mReserved           = 0;
    }
    
    return audioFmt;
}

-(void)setupAudioBufferListWithNumberFrames:(UInt32)inNumberFrames{
    
    self.bufferData = TFAllocAudioBufferData(self.audioDesc, inNumberFrames);
}

#pragma mark - audio unit callback

static OSStatus recordingCallback(void *inRefCon,
                                  
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    OSStatus status;
    TFAudioRecorder *audioRecorder = (__bridge TFAudioRecorder* )inRefCon;

    //sampleRate是一秒钟的采样次数，不是样本数，每次采样形成一个frame，即一帧；每次采样，每个声道采样一次，也就是一个frame，n个channel,n个sample。只有在单声道时，sampleRate才等于一秒钟的样本数。
    
    if (!audioRecorder.bufferData) {
        [audioRecorder setupAudioBufferListWithNumberFrames:inNumberFrames];
    }
    
    status = AudioUnitRender(audioRecorder->audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, audioRecorder.bufferData->bufferList);
    TFCheckStatusReturnStatus(status, @"AudioUnitRender");
    
    [audioRecorder transportAudioBuffersToNext];

    return noErr;
}




@end
