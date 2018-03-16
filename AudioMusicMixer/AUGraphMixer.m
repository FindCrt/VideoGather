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

#define recordBus    1
#define renderBus   0

#define leftChannelIndex  0
#define rightChannelIndex 1

#define MixerInputSourceCount   3
#define FirstAudioFileIndex     0
#define RecordUnitSourceIndex    1
#define SecondAudioFileIndex    2

#import "AUGraphMixer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TFStatusChecker.h"
#import "TFAudioFileReader.h"
#import "TFAudioFileWriter.h"
#import <AVFoundation/AVFoundation.h>

@interface AUGraphMixer (){
    AUGraph processingGraph;
    AUNode recordPlayNode;
    AUNode mixerNode;
    
    AudioUnit recordPlayUnit;
    AudioUnit mixerUnit;
    
    AudioStreamBasicDescription sourceStreamFmts[MixerInputSourceCount];
    AudioStreamBasicDescription mixStreamFmt;
    
    AudioBufferList tempRecordBuf;
    
    float volumes[MixerInputSourceCount];
}

@property (nonatomic, strong) TFAudioFileReader *fileReader;
@property (nonatomic, strong) TFAudioFileReader *fileReader2;

@property (nonatomic, strong) TFAudioFileWriter *fileWriter;

@property (nonatomic, strong) NSMutableDictionary *audioChannelTypes;

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

-(void)setVolumeAtIndex:(NSInteger)index to:(float)volume{
    volumes[index] = volume;
    
    if (mixerUnit) {
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, (UInt32)index, volume, 0);
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
    
    status = AUGraphNodeInfo(processingGraph, recordPlayNode, &playDesc, &recordPlayUnit);
    TFCheckStatusUnReturn(status, @"get play unit");
    status = AUGraphNodeInfo(processingGraph, mixerNode, NULL, &mixerUnit);
    TFCheckStatusUnReturn(status, @"get record unit");
    
    //play data callback
    AudioUnitAddRenderNotify(mixerUnit, playUnitInputCallback, (__bridge void *)self);
    
    status = AUGraphConnectNodeInput(processingGraph, mixerNode, 0, recordPlayNode, 0);
    TFCheckStatusUnReturn(status, @"connect mixer to play");
    
    //开启录音到mixer的连接，mixer的element0的回调就不调用了，即通过录音的audioUnit获取数据;
//    status = AUGraphConnectNodeInput(processingGraph, recordPlayNode, recordBus, mixerNode, 0);
//    TFCheckStatusUnReturn(status, @"connect record to mixer");
    
    //set stream formats
    [self setStramFormats];
    
    [self setupFileReaders];
    [self setupFileWriters];

    status = AUGraphInitialize(processingGraph);
    TFCheckStatusUnReturn(status, @"init graph");
    
    for (int i = 0; i<MixerInputSourceCount; i++) {
        AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, (UInt32)index, (volumes[i]?:0.5f), 0);
    }
}

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

-(OSStatus)setStramFormats{
    
    for (int i = 0; i<MixerInputSourceCount; i++) {
        if ([[self.audioChannelTypes objectForKey:@(i)] integerValue] == AUGraphMixerChannelTypeStereo) {
            sourceStreamFmts[i] = *([[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                                         sampleRate:44100
                                                                           channels:2
                                                                        interleaved:NO].streamDescription);
        }else{
            sourceStreamFmts[i] = *([[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                                         sampleRate:44100
                                                                           channels:1
                                                                        interleaved:YES].streamDescription);
        }
    }
    
    //interleaved设为NO,左右声道数据分别在不同AudioBuffer里
    mixStreamFmt = *([[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                      sampleRate:44100
                                                        channels:2
                                                     interleaved:NO].streamDescription);
    
    
    //record
    UInt32 size = sizeof(sourceStreamFmts[RecordUnitSourceIndex]);
    OSStatus status = AudioUnitSetProperty(recordPlayUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, recordBus, &sourceStreamFmts[RecordUnitSourceIndex], size);
    TFCheckStatusUnReturn(status, @"set record unit format");
    
    UInt32 flag = 1;
    status = AudioUnitSetProperty(recordPlayUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, recordBus, &flag, sizeof(flag));
    TFCheckStatusUnReturn(status, @"emable record unit IO");
    
#if UsingTempAudioBuffer
    AURenderCallbackStruct callback;
    callback.inputProc = recordingCallback;
    callback.inputProcRefCon = (__bridge void * _Nullable)(self);
    AudioUnitSetProperty(recordPlayUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, recordBus, &callback, sizeof(callback));
    TFCheckStatusUnReturn(status, @"record unit set input callback");
#endif
    
    //mixer
    UInt32 inputCount = MixerInputSourceCount;
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &inputCount, sizeof(inputCount));
    TFCheckStatusUnReturn(status, @"set mixer unit format");
    
    //设置每个输入源的回调函数和输出格式
    for (int i = 0; i<inputCount; ++i) {
        
        AURenderCallbackStruct mixerInputCallback;
        mixerInputCallback.inputProc = &mixerDataInput;
        mixerInputCallback.inputProcRefCon = (__bridge void*)self;
    
        status = AUGraphSetNodeInputCallback(processingGraph, mixerNode, i, &mixerInputCallback);
        TFCheckStatusUnReturn(status, @"set mixer node callback");
        
        status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &mixStreamFmt, sizeof(AudioStreamBasicDescription));
        TFCheckStatusUnReturn(status, @"set mixer input format");
    }
    
    status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixStreamFmt, sizeof(AudioStreamBasicDescription));
    TFCheckStatusUnReturn(status, @"set mixer output format");
    
    
    //play
    size = sizeof(mixStreamFmt);
    status = AudioUnitSetProperty(recordPlayUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, renderBus, &mixStreamFmt, size);
    TFCheckStatusUnReturn(status, @"set play unit format");

    return status;
}

-(void)setupFileReaders{
    
    _fileReader = [[TFAudioFileReader alloc] init];
    _fileReader.filePath = self.musicFilePath;
    [_fileReader setDesireOutputFormat:sourceStreamFmts[FirstAudioFileIndex]];
    _fileReader.isRepeat = YES;
    
    _fileReader2 = [[TFAudioFileReader alloc] init];
    _fileReader2.filePath = self.musicFilePath2;
    [_fileReader2 setDesireOutputFormat:sourceStreamFmts[SecondAudioFileIndex]];
    _fileReader2.isRepeat = YES;
}

-(void)setupFileWriters{
    _fileWriter = [[TFAudioFileWriter alloc] init];
    _fileWriter.filePath = self.outputPath;

    _fileWriter.fileType = kAudioFileCAFType;
    
    [_fileWriter setAudioDesc:mixStreamFmt];
}

-(void)setMusicFilePath:(NSString *)musicFilePath{
    _musicFilePath = musicFilePath;
    _fileReader.filePath = musicFilePath;
}

-(void)setMusicFilePath2:(NSString *)musicFilePath2{
    _musicFilePath2 = musicFilePath2;
    _fileReader2.filePath = musicFilePath2;
}

//存储各个输入源的声道类型
-(NSMutableDictionary *)audioChannelTypes{
    if (!_audioChannelTypes) {
        _audioChannelTypes = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    return _audioChannelTypes;
}

-(void)setAudioSourceAtIndex:(NSInteger)index channelTypeTo:(AUGraphMixerChannelType)channelType{

    [self.audioChannelTypes setObject:@(channelType) forKey:@(index)];
    
    if (channelType == AUGraphMixerChannelTypeStereo) {
        sourceStreamFmts[index] = *([[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                             sampleRate:44100
                                                               channels:2
                                                            interleaved:NO].streamDescription);
    }else{
        sourceStreamFmts[index] = *([[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                             sampleRate:44100
                                                               channels:1
                                                            interleaved:YES].streamDescription);
    }
    
    //测试方便，固定输入源1为第一个音频文件，输入源2位录音，输入源3为第二个音频文件；更好的处理是把输入源封装成单独的类，然后可以接受任意数量的输入源，任意顺序
    if (index == FirstAudioFileIndex) {
        
        [_fileReader setDesireOutputFormat:sourceStreamFmts[index]];
        
    }else if (index == RecordUnitSourceIndex){
        UInt32 size = sizeof(sourceStreamFmts[index]);
        OSStatus status = AudioUnitSetProperty(recordPlayUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, recordBus, &sourceStreamFmts[index], size);
        TFCheckStatusUnReturn(status, @"set record unit format");
    }else if (index == SecondAudioFileIndex){
        [_fileReader2 setDesireOutputFormat:sourceStreamFmts[index]];
    }
}

-(AUGraphMixerChannelType)channelTypeForSourceAt:(NSInteger)index{
    return [[_audioChannelTypes objectForKey:@(index)] integerValue];
}

#pragma mark - mixer input callback

static OSStatus mixerDataInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData){
    
    AUGraphMixer *mixer = (__bridge AUGraphMixer *)(inRefCon);
    
    //inBusNumber为输入源的索引，根据这个值来从不用源获取音频数据
    if (inBusNumber == FirstAudioFileIndex) {
        
        [mixer readAudioFile:0 numberFrames:inNumberFrames toBuffer:ioData];
        
    }else if (inBusNumber == RecordUnitSourceIndex){
        
        [mixer readRecordedAudio:ioActionFlags timeStamp:inTimeStamp numberFrames:inNumberFrames toBuffer:ioData];
    }else if (inBusNumber == SecondAudioFileIndex){
        [mixer readAudioFile:1 numberFrames:inNumberFrames toBuffer:ioData];
    }
    
    return 0;
}

-(OSStatus)readAudioFile:(NSInteger)fileIndex numberFrames:(UInt32)inNumberFrames toBuffer:(AudioBufferList *)ioData{
    UInt32 numberFrames = inNumberFrames;
    
    TFAudioFileReader *fileReader = nil;
    NSInteger sourceIndex = 0;
    if (fileIndex == 0) {
        fileReader = self.fileReader;
        sourceIndex = FirstAudioFileIndex;
    }else if (fileIndex == 1){
        fileReader = self.fileReader2;
        sourceIndex = SecondAudioFileIndex;
    }
    
    AUGraphMixerChannelType channelType = [[_audioChannelTypes objectForKey:@(sourceIndex)] integerValue];
    
    if (channelType == AUGraphMixerChannelTypeStereo) {
        
        //这时格式需要设为双声道
        TFAudioBufferData *bufferData = TFCreateAudioBufferData(ioData, inNumberFrames);
        return [fileReader readFrames:&numberFrames toBufferData:bufferData];
        
    }else{
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        
        if (channelType == AUGraphMixerChannelTypeLeft) {
            
            bufList.mBuffers[0] = ioData->mBuffers[leftChannelIndex]; //只取左边声道
            memset(ioData->mBuffers[rightChannelIndex].mData, 0, ioData->mBuffers[rightChannelIndex].mDataByteSize);
        }else if (channelType == AUGraphMixerChannelTypeRight){
            
            bufList.mBuffers[0] = ioData->mBuffers[rightChannelIndex]; //只取右边声道，把文件音频读入到右侧
            memset(ioData->mBuffers[leftChannelIndex].mData, 0, ioData->mBuffers[leftChannelIndex].mDataByteSize);
        }
        
        TFAudioBufferData *bufferData = TFCreateAudioBufferData(&bufList, inNumberFrames);
        return [fileReader readFrames:&numberFrames toBufferData:bufferData];
    }
}

-(OSStatus)readRecordedAudio:(AudioUnitRenderActionFlags *)ioActionFlags timeStamp:(const AudioTimeStamp *)inTimeStamp numberFrames:(UInt32)inNumberFrames toBuffer:(AudioBufferList *)ioData{
    
    AUGraphMixerChannelType channelType = [[_audioChannelTypes objectForKey:@(RecordUnitSourceIndex)] integerValue];
    
    if (channelType == AUGraphMixerChannelTypeStereo) {
        
        //NonInterleaved时，读取出来是单声道的，ioData->mBuffers[1]的数据是空的，测试为iPhone6.使用电脑模拟器是有数据，只是两声道数据一样。可能是iPhone6硬件支持问题，待研究。
        OSStatus status = AudioUnitRender(recordPlayUnit, ioActionFlags, inTimeStamp, recordBus, inNumberFrames, ioData);
        memcpy(ioData->mBuffers[1].mData, ioData->mBuffers[0].mData, ioData->mBuffers[1].mDataByteSize);
        
        return status;
        
    }else{
        
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        
        if (channelType == AUGraphMixerChannelTypeLeft) {
            bufList.mBuffers[0] = ioData->mBuffers[leftChannelIndex]; //只填充左声道数据
            memset(ioData->mBuffers[rightChannelIndex].mData, 0, ioData->mBuffers[rightChannelIndex].mDataByteSize);
        }else if (channelType == AUGraphMixerChannelTypeRight){
            bufList.mBuffers[0] = ioData->mBuffers[rightChannelIndex];
            memset(ioData->mBuffers[leftChannelIndex].mData, 0, ioData->mBuffers[leftChannelIndex].mDataByteSize);
        }
        
        OSStatus status = AudioUnitRender(recordPlayUnit, ioActionFlags, inTimeStamp, recordBus, inNumberFrames, &bufList);
        return status;
    }
}

static OSStatus playUnitInputCallback(void *inRefCon,
                                  
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    
    //获取数据
    if ((*ioActionFlags) & kAudioUnitRenderAction_PostRender){
        AUGraphMixer *mixer = (__bridge AUGraphMixer *)inRefCon;
        TFAudioBufferData *tf_audioBuf = TFCreateAudioBufferData(ioData, inNumberFrames);
        [mixer.fileWriter receiveNewAudioBuffers:tf_audioBuf];
    }

    
    return noErr;
}

@end
