//
//  TFAudioMixer.m
//  VideoGather
//
//  Created by shiwei on 17/11/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

/*
 * 1. 采样率率不同,合成不了
 * 2. 取值错误，*(xxx+1)写成了*xxx+1
 *
 */

#import "TFAudioMixer.h"

#define TFAudioSourcePullTimePerSecond   50

@interface TFAudioMixer (){
    TFAudioBufferData *audioBuffer1;
    TFAudioBufferData *audioBuffer2;
    
    BOOL _shouldMix;
}

@end

@implementation TFAudioMixer

//call by push audio source
-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    [super setAudioDesc:audioDesc];

    
    if (self.sourceType == TFAudioMixerSourceTypeOnePushOnePull &&
        [_pullAudioSource outputDesc].mSampleRate != audioDesc.mSampleRate) {
        
        NSLog(@"override pullAudioSource's sampleRate");
        [_pullAudioSource setDesireSampleRate:audioDesc.mSampleRate];
    }
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData{
    [self receiveNewAudioBuffers:bufferData inputIndex:0];
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData inputIndex:(NSInteger)inputIndex{
    
    NSAssert(self.sourceType != TFAudioMixerSourceTypeTwoPull, @"with sourceType of two pull,mix don't receive audio buffer");
    
    if (self.sourceType == TFAudioMixerSourceTypeOnePushOnePull) {
        
        //TODO:如果处理时间太长，有丢帧风险
        //一个主动输入源，只对应audioBuffer1,且只取第一个输入源
        if (inputIndex == 0) {
            TFCopyAudioBufferData(&bufferData, &audioBuffer1);
            
            [self pullBufferFromAudioSource];
            [self mixAudioBuffer];
        }
        
    }else if (self.sourceType == TFAudioMixerSourceTypeTwoPush){
        
        //双主动输入源，根据索引判断输入源，需要缓冲区的支持,否则后面来的数据会挤掉前面的，而前面的可能还没有开始处理
        if (inputIndex == 0) {
           
        }else{
            
        }
    }
}

-(void)start{
    if (self.sourceType == TFAudioMixerSourceTypeTwoPull) {
        _shouldMix = YES;
        [self startAudioSourcePullLoop];
    }
}

-(void)stop{
    if (self.sourceType == TFAudioMixerSourceTypeTwoPull) {
        _shouldMix = NO;
    }
}

-(void)mixAudioBuffer{
    
    memset(self.bufferData->bufferList.mBuffers[0].mData, 0, self.bufferData->bufferList.mBuffers[0].mDataByteSize);
    
    mixBuffer1(audioBuffer1->bufferList.mBuffers[0].mData,
               audioBuffer1->inNumberFrames,
               audioBuffer2->bufferList.mBuffers[0].mData,
               audioBuffer2->inNumberFrames,
               self.bufferData->bufferList.mBuffers[0].mData);
    
    TFUnrefAudioBufferData(audioBuffer1);
    
    [self transportAudioBuffersToNext];
}

#pragma mark - mix functions

int printInterval = 100;
int count = 0;
void mixBuffer1(SInt16 *buffer1, UInt32 frameCount1, SInt16 *buffer2 ,UInt32 frameCount2, SInt16 *outBuffer){
    
    UInt8 bitOffset = 8 * sizeof(SInt16);
    UInt64 bitMax = (UInt64) (pow(2, bitOffset));
    UInt64 bitMid = bitMax/2;

    UInt32 frameCount = MAX(frameCount1, frameCount2);
    UInt32 minFrames = MIN(frameCount1, frameCount2);
    
    UInt32 length = frameCount;
    for (int j = 0; j < length; j++)
    {
        if (j < minFrames)
        {
            SInt32 sValue =0;
            
            //record voice is too low
//            *(buffer1+j) <<= 8;
            
            SInt16 value1 = *(buffer1+j);   //-32768 ~ 32767
            SInt16 value2 = *(buffer2+j);   //-32768 ~ 32767
            
            
            SInt8 sign1 = (value1 == 0)? 0 : abs(value1)/value1;
            SInt8 sign2 = (value2== 0)? 0 : abs(value2)/value2;
            
            if (sign1 == sign2)
            {
                UInt32 tmp = ((value1 * value2) >> (bitOffset -1));
                
                sValue = value1 + value2 - sign1 * tmp;
                
                if (abs(sValue) >= bitMid)
                {
                    sValue = sign1 * (bitMid -  1);
                }
            }
            else
            {
                SInt32 tmpValue1 = value1 + bitMid;
                SInt32 tmpValue2 = value2 + bitMid;
                
                UInt32 tmp = ((tmpValue1 * tmpValue2) >> (bitOffset -1));
                
                if (tmpValue1 < bitMid && tmpValue2 < bitMid)
                {
                    sValue = tmp;
                }
                else
                {
                    sValue = 2 * (tmpValue1  + tmpValue2 ) - tmp - bitMax;
                }
                sValue -= bitMid;
            }
            
            if (abs(sValue) >= bitMid)
            {
                SInt8 sign = abs(sValue)/sValue;
                
                sValue = sign * (bitMid -  1);
            }
            
            *(outBuffer +j) = sValue;
//            *(outBuffer +j) = value2;
            
            count++;
            if (count % printInterval == 0) {
                NSLog(@"(%d)recordValue:%d, musicValue: %d, result: %d, changed:%d",j,value1, value2, sValue, abs(sValue-value2));
                count = 0;
            }
            
        }
        else{
            if (frameCount == frameCount1)
            {
                //将buffer1中的剩余数据添加到outbuffer
                *(outBuffer +j) = *(buffer1 + j);
            }
            else
            {
                //将buffer1中的剩余数据添加到outbuffer
                *(outBuffer +j) = *(buffer2 + j);
            }
        }
    }

}

#pragma mark - one pull one push

-(void)pullBufferFromAudioSource{
    NSAssert(_pullAudioSource, @"缺少静态音频数据源");
    
    //假设采样率和声道数一致，两者frame数相同
    UInt32 framesNum = audioBuffer1->inNumberFrames;
    
    if (!audioBuffer2 && !self.bufferData) {
        
        audioBuffer2 = TFAllocAudioBufferData(self.audioDesc, framesNum);
        self.bufferData = TFAllocAudioBufferData(self.audioDesc, framesNum);
    }
    memset(audioBuffer2->bufferList.mBuffers[0].mData, 0, audioBuffer2->bufferList.mBuffers[0].mDataByteSize);
    [_pullAudioSource readFrames:&framesNum toBufferData:audioBuffer2];
}

#pragma mark - pull two 

-(void)startAudioSourcePullLoop{
    
    NSAssert(_pullAudioSource && _pullAudioSource2, @"Mixer must has two pullAudioSource when it's sourceType is TFAudioMixerSourceTypeTwoPull!");
    
    //除了采样率，其他都按照“s16单声道的PCM”设置
    if ([_pullAudioSource outputDesc].mSampleRate != [_pullAudioSource2 outputDesc].mSampleRate) {
        Float32 maxSampleRate = MAX([_pullAudioSource outputDesc].mSampleRate, [_pullAudioSource2 outputDesc].mSampleRate);
        [_pullAudioSource setDesireSampleRate:maxSampleRate];
        [_pullAudioSource2 setDesireSampleRate:maxSampleRate];
        
        NSLog(@"maxSampleRate %.0f",maxSampleRate);
    }
    
    _runing = YES;
    
    //set audio desc
    [self setAudioDesc:[_pullAudioSource outputDesc]];
    
    //plan1: dont care pull rate
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UInt32 framesNum1 = 1024, framesNum2 = framesNum1;
        audioBuffer1 = TFAllocAudioBufferData(self.audioDesc, framesNum1);
        audioBuffer2 = TFAllocAudioBufferData(self.audioDesc, framesNum2);
        
        self.bufferData = TFAllocAudioBufferData(self.audioDesc, framesNum1);
        
        while (framesNum1 > 0 && framesNum2 > 0 && _shouldMix) {
            
            memset(audioBuffer1->bufferList.mBuffers[0].mData, 0, audioBuffer1->bufferList.mBuffers[0].mDataByteSize);
            memset(audioBuffer2->bufferList.mBuffers[0].mData, 0, audioBuffer2->bufferList.mBuffers[0].mDataByteSize);
            
            [_pullAudioSource readFrames:&framesNum1 toBufferData:audioBuffer1];
            [_pullAudioSource2 readFrames:&framesNum2 toBufferData:audioBuffer2];
            
            [self mixAudioBuffer];
        }
        
        _runing = NO;
        _shouldMix = NO;

    });
    
    //plan2: stable pull rate
    
    
}

@end
