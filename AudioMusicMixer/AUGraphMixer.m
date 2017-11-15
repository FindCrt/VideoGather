//
//  AUGraphMixer.m
//  VideoGather
//
//  Created by shiwei on 17/11/14.
//  Copyright © 2017年 shiwei. All rights reserved.
//

//这个表不错：https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/UsingSpecificAudioUnits/UsingSpecificAudioUnits.html

//https://developer.apple.com/library/content/technotes/tn2112/_index.html

//例子：https://developer.apple.com/library/content/samplecode/iOSMultichannelMixerTest/Introduction/Intro.html

//https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/Art/audioUnitScopes_2x.png

#import "AUGraphMixer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TFStatusChecker.h"
#import "TFAudioFileReader.h"

@interface AUGraphMixer (){
    AUGraph processingGraph;
    AUNode playNode;
//    AUNode recordInputNode;
    AUNode mixerNode;
    
    AudioUnit playUnit;
//    AudioUnit recordUnit;
    AudioUnit mixerUnit;
    
    AudioStreamBasicDescription inputStreamFmt;
    AudioStreamBasicDescription outputStreamFmt;
}

@property (nonatomic, strong) TFAudioFileReader *fileReader;

@end

@implementation AUGraphMixer

-(void)start{
    AUGraphStart(processingGraph);
    _runing = YES;
}

-(void)stop{
    Boolean graphIsRuning = false;
    AUGraphIsRunning(processingGraph, &graphIsRuning);
    if (graphIsRuning) {
        AUGraphStop(processingGraph);
    }
    _runing = NO;
}

-(void)setupAUGraph{
    NewAUGraph(&processingGraph);
    
    OSStatus status = 0;
//    //record
//    AudioComponentDescription recordDesc;
//    recordDesc.componentType = kAudioUnitType_Output;
//    recordDesc.componentSubType = kAudioUnitSubType_RemoteIO;
//    recordDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
//    recordDesc.componentFlagsMask = 0;
//    recordDesc.componentFlags = 0;
//    status = AUGraphAddNode(processingGraph, &recordDesc, &recordInputNode);
//    status = AUGraphAddNode(processingGraph, &recordDesc, &recordInputNode);
//    TFCheckStatusUnReturn(status, @"add record node");
    
    
    //play
    AudioComponentDescription playDesc;
    playDesc.componentType = kAudioUnitType_Output;
    playDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    playDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    playDesc.componentFlagsMask = 0;
    playDesc.componentFlags = 0;
    status = AUGraphAddNode(processingGraph, &playDesc, &playNode);
    TFCheckStatusUnReturn(status, @"add play node");
    
    //mixer
    AudioComponentDescription mixerDesc;
    mixerDesc.componentType = kAudioUnitType_Mixer;
    mixerDesc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerDesc.componentFlagsMask = 0;
    mixerDesc.componentFlags = 0;
    status = AUGraphAddNode(processingGraph, &mixerDesc, &mixerNode);
    TFCheckStatusUnReturn(status, @"add mixer node");
    
    status = AUGraphOpen(processingGraph);
    TFCheckStatusUnReturn(status, @"graph open");
    
//    status = AUGraphNodeInfo(processingGraph, recordInputNode, NULL, &recordUnit);
//    TFCheckStatusUnReturn(status, @"get record unit");
    status = AUGraphNodeInfo(processingGraph, playNode, NULL, &playUnit);
    TFCheckStatusUnReturn(status, @"get play unit");
    status = AUGraphNodeInfo(processingGraph, mixerNode, NULL, &mixerUnit);
    TFCheckStatusUnReturn(status, @"get record unit");
    
    status = AUGraphConnectNodeInput(processingGraph, mixerNode, 0, playNode, 0);
    TFCheckStatusUnReturn(status, @"connect mixer to play");
    
    status = AUGraphConnectNodeInput(processingGraph, playNode, 1, mixerNode, 0);
    TFCheckStatusUnReturn(status, @"connect record to mixer");
    
    //set stream formats
    [self setStramFormats];
    
    [self setupFileReader];
    
    status = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, 0.8f, 0);
    TFCheckStatusUnReturn(status, @"set mixer volume");
    
    status = AUGraphInitialize(processingGraph);
    TFCheckStatusUnReturn(status, @"init graph");
}

-(OSStatus)setStramFormats{
    inputStreamFmt.mSampleRate = 44100;
    inputStreamFmt.mFormatID = kAudioFormatLinearPCM;
    inputStreamFmt.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    inputStreamFmt.mFramesPerPacket = 1;
    inputStreamFmt.mChannelsPerFrame = 2;
    inputStreamFmt.mBitsPerChannel = 16;
    inputStreamFmt.mBytesPerFrame = inputStreamFmt.mBitsPerChannel * inputStreamFmt.mChannelsPerFrame / 8;
    inputStreamFmt.mBytesPerPacket = inputStreamFmt.mBytesPerFrame * inputStreamFmt.mFramesPerPacket;
    inputStreamFmt.mReserved = 0;
    
    outputStreamFmt = inputStreamFmt;
//    outputStreamFmt.mChannelsPerFrame = 2;
    
    //record
    UInt32 size = sizeof(inputStreamFmt);
    OSStatus status = AudioUnitSetProperty(playUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &inputStreamFmt, size);
    TFCheckStatusUnReturn(status, @"set record unit format");
//    AURenderCallbackStruct callbackStruct;
//    callbackStruct.inputProc = recordingCallback;
//    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
//    status = AudioUnitSetProperty(recordUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &callbackStruct, sizeof(AURenderCallbackStruct));
//    TFCheckStatusUnReturn(status, @"set record callback");
    UInt32 flag = 1;
    status = AudioUnitSetProperty(playUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    TFCheckStatusUnReturn(status, @"emable record unit IO");
    
    //play
    size = sizeof(inputStreamFmt);
    status = AudioUnitSetProperty(playUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outputStreamFmt, size);
    TFCheckStatusUnReturn(status, @"set play unit format");
    
    //mixer
    UInt32 inputCount = 2;
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &inputCount, sizeof(inputCount));
    TFCheckStatusUnReturn(status, @"set mixer unit format");
    
    for (int i = 1; i<inputCount; ++i) {  //0 使用record node输入
        
        AURenderCallbackStruct mixerInputCallback;
        mixerInputCallback.inputProc = &mixerDataInput;
        mixerInputCallback.inputProcRefCon = (__bridge void*)self;
        
        status = AUGraphSetNodeInputCallback(processingGraph, mixerNode, i, &mixerInputCallback);
        TFCheckStatusUnReturn(status, @"set mixer node callback");
        
        status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &inputStreamFmt, sizeof(AudioStreamBasicDescription));
        TFCheckStatusUnReturn(status, @"set mixer input format");
    }
    
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &outputStreamFmt, sizeof(AudioStreamBasicDescription));
    TFCheckStatusUnReturn(status, @"set mixer output format");

    return status;
}

-(void)setupFileReader{
    _fileReader = [[TFAudioFileReader alloc] init];
    _fileReader.filePath = self.musicFilePath;
    [_fileReader setDesireOutputFormat:inputStreamFmt];
    _fileReader.isRepeat = YES;
}

-(void)setMusicFilePath:(NSString *)musicFilePath{
    _musicFilePath = musicFilePath;
    _fileReader.filePath = musicFilePath;
}

#pragma mark - mixer input callback

static OSStatus mixerDataInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData){
    
    AUGraphMixer *mixer = (__bridge AUGraphMixer *)(inRefCon);
    if (inBusNumber == 1) {
        UInt32 numberFrames = inNumberFrames;
        TFAudioBufferData *bufferData = TFCreateAudioBufferData(ioData, inNumberFrames);
        return [mixer.fileReader readFrames:&numberFrames toBufferData:bufferData];
    }
    
    return 0;
}

#pragma mark - record callback
//
//static OSStatus recordingCallback(void *inRefCon,
//                                  
//                                  AudioUnitRenderActionFlags *ioActionFlags,
//                                  const AudioTimeStamp *inTimeStamp,
//                                  UInt32 inBusNumber,
//                                  UInt32 inNumberFrames,
//                                  AudioBufferList *ioData) {
//    
//}


@end
