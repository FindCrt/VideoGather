//
//  TFAudioMixer.m
//  VideoGather
//
//  Created by shiwei on 17/11/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioMixer.h"

@interface TFAudioMixer (){
    TFAudioBufferData *audioBuffer1;
    TFAudioBufferData *audioBuffer2;
}

@end

@implementation TFAudioMixer

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    [super setAudioDesc:audioDesc];
    
    
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData{
    [self receiveNewAudioBuffers:bufferData inputIndex:0];
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData inputIndex:(NSInteger)inputIndex{
    
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

-(void)pullBufferFromAudioSource{
    NSAssert(_pullAudioSource, @"缺少静态音频数据源");

    //假设采样率和声道数一致，两者frame数相同
    UInt32 framesNum = audioBuffer1->inNumberFrames;
    
    if (!audioBuffer2 && !self.bufferData) {
        
        audioBuffer2 = TFAllocAudioBufferData(self.audioDesc, framesNum);
        self.bufferData = TFAllocAudioBufferData(self.audioDesc, framesNum);
    }
    memset(audioBuffer2->bufferList.mBuffers[0].mData, 0, audioBuffer2->bufferList.mBuffers[0].mDataByteSize);
    [_pullAudioSource readFrames:framesNum toBufferData:audioBuffer2];
}

-(void)mixAudioBuffer{
    
    memset(self.bufferData->bufferList.mBuffers[0].mData, 0, self.bufferData->bufferList.mBuffers[0].mDataByteSize);
    
    mixBuffer1(audioBuffer1->bufferList.mBuffers[0].mData,
               audioBuffer1->inNumberFrames,
               audioBuffer2->bufferList.mBuffers[0].mData,
               audioBuffer2->inNumberFrames,
               self.bufferData->bufferList.mBuffers[0].mData);
    
    TFUnrefAudioBufferData(audioBuffer1);
    
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>mix completed!");
    
    [self transportAudioBuffersToNext];
}

int printInterval = 100;
int count = 0;
void mixBuffer1(SInt16 *buffer1, UInt32 frameCount1, SInt16 *buffer2 ,UInt32 frameCount2, SInt16 *outBuffer){
    
    UInt8 bitOffset = 8 * sizeof(SInt16);
    UInt64 bitMax = (UInt64) (pow(2, bitOffset));
    UInt64 bitMid = bitMax/2;

    UInt32 frameCount = MAX(frameCount1, frameCount2);
    UInt32 minFrames = MIN(frameCount1, frameCount2);
    
    for (int i = 0; i< frameCount1; i++) {
        *(outBuffer+i) = *(buffer2+i);
    }
    
    return;
    
    UInt32 length = frameCount;
    for (int j = 0; j < length; j++)
    {
        if (j < minFrames)
        {
            SInt32 sValue =0;
            
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

@end
