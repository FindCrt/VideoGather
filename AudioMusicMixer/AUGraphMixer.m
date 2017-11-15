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

#define inputBus    1
#define renderBus   0

#import "AUGraphMixer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TFStatusChecker.h"
#import "TFAudioFileReader.h"
#import <AVFoundation/AVFoundation.h>

@interface AUGraphMixer (){
    AUGraph processingGraph;
    AUNode recordPlayNode;
//    AUNode recordInputNode;
    AUNode mixerNode;
    
    AudioUnit recordPlayUnit;
//    AudioUnit recordUnit;
    AudioUnit mixerUnit;
    
    AudioStreamBasicDescription sourceStreamFmt;
    AudioStreamBasicDescription mixStreamFmt;
    
    void *recordBuffer; //环形缓冲区，暂存录音数据
    UInt32 recordTotalLength;
    UInt32 startIndex;
    UInt32 endIndex;
    
    
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

-(void)setLeftVolume:(float)leftVolume{
    _leftVolume = leftVolume;
    
    if (_runing) {
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, _leftVolume, 0);
    }
}

-(void)setRightVolume:(float)rightVolume{
    _rightVolume = rightVolume;
    if (_runing) {
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, _rightVolume, 0);
    }
}

-(void)setupAUGraph{
    NewAUGraph(&processingGraph);
    
    OSStatus status = 0;
    
    //play & record
    AudioComponentDescription playDesc;
    playDesc.componentType = kAudioUnitType_Output;
    playDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    playDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    playDesc.componentFlagsMask = 0;
    playDesc.componentFlags = 0;
    status = AUGraphAddNode(processingGraph, &playDesc, &recordPlayNode);
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
    status = AUGraphNodeInfo(processingGraph, recordPlayNode, NULL, &recordPlayUnit);
    TFCheckStatusUnReturn(status, @"get play unit");
    status = AUGraphNodeInfo(processingGraph, mixerNode, NULL, &mixerUnit);
    TFCheckStatusUnReturn(status, @"get record unit");
    
    status = AUGraphConnectNodeInput(processingGraph, mixerNode, 0, recordPlayNode, 0);
    TFCheckStatusUnReturn(status, @"connect mixer to play");
    
    //开启录音到mixer的连接，mixer的element0的回调就不调用了，即通过录音的audioUnit获取数据
//    status = AUGraphConnectNodeInput(processingGraph, recordPlayNode, inputBus, mixerNode, 0);
//    TFCheckStatusUnReturn(status, @"connect record to mixer");
    
    //set stream formats
    [self setStramFormats];
    
    [self setupFileReader];
    
    //element0 left
    status = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, _leftVolume, 0);
    TFCheckStatusUnReturn(status, @"set mixer volume");
    
    //element1 right
    status = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 1, _rightVolume, 0);
    TFCheckStatusUnReturn(status, @"set mixer volume");
    

    
    status = AUGraphInitialize(processingGraph);
    TFCheckStatusUnReturn(status, @"init graph");
}

-(OSStatus)setStramFormats{
    
    sourceStreamFmt = *([[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                         sampleRate:44100
                                                           channels:1
                                                        interleaved:YES].streamDescription);
    mixStreamFmt = *([[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                      sampleRate:sourceStreamFmt.mSampleRate
                                                        channels:2
                                                     interleaved:NO].streamDescription);
    
//    sourceStreamFmt.mSampleRate = 44100;
//    sourceStreamFmt.mFormatID = kAudioFormatLinearPCM;
//    sourceStreamFmt.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
//    sourceStreamFmt.mFramesPerPacket = 1;
//    sourceStreamFmt.mChannelsPerFrame = 1;
//    sourceStreamFmt.mBitsPerChannel = 16;
//    sourceStreamFmt.mBytesPerFrame = sourceStreamFmt.mBitsPerChannel * sourceStreamFmt.mChannelsPerFrame / 8;
//    sourceStreamFmt.mBytesPerPacket = sourceStreamFmt.mBytesPerFrame * sourceStreamFmt.mFramesPerPacket;
//    sourceStreamFmt.mReserved = 0;
//
//    mixStreamFmt = sourceStreamFmt;
//    //混音组件使用不交错(NonInterleaved)的格式，那么回调方法的参数ioData就包含多个buffer，每个对应一个声道,而不是一个buffer里面包含多个声道，这样就可以方便的对单个声道数据进行处理
//    mixStreamFmt.mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
//    mixStreamFmt.mChannelsPerFrame = 2;
    
    //record
    UInt32 size = sizeof(sourceStreamFmt);
    OSStatus status = AudioUnitSetProperty(recordPlayUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputBus, &sourceStreamFmt, size);
    TFCheckStatusUnReturn(status, @"set record unit format");
    
//    AURenderCallbackStruct callbackStruct;
//    callbackStruct.inputProc = recordingCallback;
//    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
//    status = AudioUnitSetProperty(recordPlayUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, inputBus, &callbackStruct, sizeof(AURenderCallbackStruct));
//    TFCheckStatusUnReturn(status, @"set record callback");
    
    UInt32 flag = 1;
    status = AudioUnitSetProperty(recordPlayUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, inputBus, &flag, sizeof(flag));
    TFCheckStatusUnReturn(status, @"emable record unit IO");
    
    //mixer
    UInt32 inputCount = 2;
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &inputCount, sizeof(inputCount));
    TFCheckStatusUnReturn(status, @"set mixer unit format");
    
    for (int i = 0; i<inputCount; ++i) {  //0 使用record node输入
        
        AURenderCallbackStruct mixerInputCallback;
        mixerInputCallback.inputProc = &mixerDataInput;
        mixerInputCallback.inputProcRefCon = (__bridge void*)self;
        
        status = AUGraphSetNodeInputCallback(processingGraph, mixerNode, i, &mixerInputCallback);
        TFCheckStatusUnReturn(status, @"set mixer node callback");
        
        status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &mixStreamFmt, sizeof(AudioStreamBasicDescription));
        TFCheckStatusUnReturn(status, @"set mixer input format");
    }
    
    NSLog(@"123");
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixStreamFmt, sizeof(AudioStreamBasicDescription));
    TFCheckStatusUnReturn(status, @"set mixer output format");
    
    
    //play
    size = sizeof(mixStreamFmt);
    status = AudioUnitSetProperty(recordPlayUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, renderBus, &mixStreamFmt, size);
    TFCheckStatusUnReturn(status, @"set play unit format");

    return status;
}

-(void)setupFileReader{
    _fileReader = [[TFAudioFileReader alloc] init];
    _fileReader.filePath = self.musicFilePath;
    [_fileReader setDesireOutputFormat:sourceStreamFmt];
    _fileReader.isRepeat = YES;
}

-(void)setMusicFilePath:(NSString *)musicFilePath{
    _musicFilePath = musicFilePath;
    _fileReader.filePath = musicFilePath;
}

#pragma mark - record buffer

-(void)setupRecordBuffers{
    recordTotalLength = sourceStreamFmt.mBytesPerFrame * 2048;
    recordBuffer = malloc(recordTotalLength);
    startIndex = 0;
    endIndex = 0;
}

-(void)readLength:(UInt32 *)lengthP toBuffer:(void *)buffer{
    UInt32 length = *lengthP;
    
    if (startIndex == endIndex) {
        *lengthP = 0;
        return;
    }
    
    if (endIndex > startIndex) {
        if (startIndex + length <= endIndex) {
            memcpy(buffer, recordBuffer+startIndex, length);
            startIndex += length;
        }else{
            memcpy(buffer, recordBuffer+startIndex, endIndex - startIndex);
            startIndex = endIndex;
            *lengthP = endIndex - startIndex;
        }
    }else{
        UInt32 rightPartLen = recordTotalLength - startIndex;
        UInt32 leftPartLen = endIndex;
        
        if (rightPartLen >= length) {
            memcpy(buffer, recordBuffer+startIndex, length);
            startIndex += length;
            if (startIndex == recordTotalLength) {
                startIndex = 0;
            }
            
        }else if (leftPartLen + rightPartLen >= length) {
            memcpy(buffer, recordBuffer+startIndex, rightPartLen);
            memcpy(buffer+rightPartLen, recordBuffer, length - rightPartLen);
            startIndex = length - rightPartLen;
        }else{
            memcpy(buffer, recordBuffer+startIndex, rightPartLen);
            memcpy(buffer+rightPartLen, recordBuffer, leftPartLen);
            
            startIndex = endIndex;
            *lengthP = length - (leftPartLen + rightPartLen);
        }
    }
}

-(void)insertBuffer:(void *)buffer length:(UInt32)length{
    
    if (endIndex >= startIndex) {
        if (endIndex + length < recordTotalLength) {
            memcpy(recordBuffer+endIndex, buffer, length);
            endIndex += length;
        }else{
            UInt32 trailLen = recordTotalLength - endIndex;
            memcpy(recordBuffer+endIndex, buffer, trailLen);
            memcpy(recordBuffer, buffer+trailLen, length - trailLen);
            
            endIndex = length - trailLen;
            if (endIndex > startIndex) {
                NSLog(@"数据覆盖，需要增大缓冲区");
            }
        }
    }else{
        memcpy(recordBuffer+endIndex, buffer, length);
        endIndex += length;
        if (endIndex > startIndex) {
            NSLog(@"数据覆盖，需要增大缓冲区");
        }
    }
}

#pragma mark - mixer input callback

static OSStatus mixerDataInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData){
    
    AUGraphMixer *mixer = (__bridge AUGraphMixer *)(inRefCon);
    
    if (inBusNumber == 1) {
        UInt32 numberFrames = inNumberFrames;
        
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0] = ioData->mBuffers[1]; //只取右边声道，把文件音频读入到右侧
        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
        
        TFAudioBufferData *bufferData = TFCreateAudioBufferData(&bufList, inNumberFrames);
        return [mixer.fileReader readFrames:&numberFrames toBufferData:bufferData];
    }else if (inBusNumber == 0){
//        UInt32 needLength = inNumberFrames *  mixer->sourceStreamFmt.mBytesPerFrame;
//        UInt32 readLen = needLength;
//        
//        do {
//            [mixer readLength:&readLen toBuffer:ioData->mBuffers[0].mData];
//            needLength -= readLen;
//            readLen = needLength;
//            
//        } while (needLength > 0);
        
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0] = ioData->mBuffers[0];
        AudioUnitRender(mixer->recordPlayUnit, ioActionFlags, inTimeStamp, inputBus, inNumberFrames, &bufList);
        memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
    }
    
    return 0;
}

#pragma mark - record callback

//static OSStatus recordingCallback(void *inRefCon,
//                                  AudioUnitRenderActionFlags *ioActionFlags,
//                                  const AudioTimeStamp *inTimeStamp,
//                                  UInt32 inBusNumber,
//                                  UInt32 inNumberFrames,
//                                  AudioBufferList *ioData) {
//    
//    AudioUnitRender(<#AudioUnit  _Nonnull inUnit#>, <#AudioUnitRenderActionFlags * _Nullable ioActionFlags#>, <#const AudioTimeStamp * _Nonnull inTimeStamp#>, <#UInt32 inOutputBusNumber#>, <#UInt32 inNumberFrames#>, <#AudioBufferList * _Nonnull ioData#>)
//    
//}


@end
