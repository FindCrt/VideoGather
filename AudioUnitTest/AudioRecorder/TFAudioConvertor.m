//
//  TFAudioConvertor.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

/**
 参考：http://blog.csdn.net/andyhuabing/article/details/40983423
 http://www.mamicode.com/info-detail-986202.html
 http://www.cnblogs.com/caosiyang/archive/2012/07/16/2594029.html
*/

#import "TFAudioConvertor.h"

//#define AAC_FRAME_NUM_PER_PACKET    1024
#define PACKET_PER_CONVERT          1

@interface TFAudioConvertor (){
    AudioConverterRef _audioConverter;
    
    void *_convertedDataBuf;
    uint64_t bufferLengthPerConvert; //每次转换需要的数据长度
    
    void *leftBuf;
    uint64_t leftLength;
    
    UInt32 outPacketLength;     //转换后输入的数据包最大数据长度，单位字节
}

@end

@implementation TFAudioConvertor

-(instancetype)init{
    if (self = [super init]) {
        
        self.bufferData = TFCreateAudioBufferData(NULL, 0);
    }
    
    return self;
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    [super setAudioDesc:audioDesc];
    
    //根据输入数据格式确定每次转换需要的数据长度
    bufferLengthPerConvert = audioDesc.mBytesPerFrame*_outputDesc.mFramesPerPacket*PACKET_PER_CONVERT;
    _convertedDataBuf = malloc(bufferLengthPerConvert);
    leftBuf = malloc(bufferLengthPerConvert);
    
    [self setupAudioConverter];
}

//根据数据格式调整输出格式
-(AudioStreamBasicDescription)outputAudioDescWithInputDesc:(AudioStreamBasicDescription)audioDesc{

    if (_outputDesc.mSampleRate == 0) {
        _outputDesc.mSampleRate = audioDesc.mSampleRate;
    }
    
    if (_outputDesc.mChannelsPerFrame == 0) {
        _outputDesc.mChannelsPerFrame = audioDesc.mChannelsPerFrame;
    }
    
    return _outputDesc;
}

-(void)setupAudioConverter{
    AudioStreamBasicDescription sourceDesc = self.audioDesc;
    AudioClassDescription hardwareCodec[1] = {
        {
            kAudioEncoderComponentType,
            _outputDesc.mFormatID,
            kAppleHardwareAudioCodecManufacturer
        }
    };
    OSStatus status = AudioConverterNewSpecific(&sourceDesc, &_outputDesc, 1, hardwareCodec, &_audioConverter);
    
    TFCheckStatus(status, @"create audio convert failed!");
    
    //获取输出数据大小
    UInt32 size = sizeof(outPacketLength);
    AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &outPacketLength);
    
    BOOL canResume = NO;
    size = sizeof(canResume);
    status = AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyCanResumeFromInterruption, &size, &canResume);
    
    if (status != 0) {
        NSLog(@"audio convertor isn't hardware codec");
    }
    
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData{
    
    if (_audioConverter == nil) {
        return;
    }
    
    TFRefAudioBufferData(bufferData);
    AudioBuffer *inBuffer = & bufferData->bufferList->mBuffers[0];
    
    
    void *current = nil;
    uint64_t lastLeftLength = leftLength; //使用上次接收数据处理后遗留的长度做判断
    
    if (lastLeftLength + inBuffer->mDataByteSize >= bufferLengthPerConvert){  //可以至少读取一次
        if (lastLeftLength > 0) { //有遗留则先拷贝一份单位长度进行处理，剩余的不拷贝
            memcpy(leftBuf+lastLeftLength, inBuffer->mData, bufferLengthPerConvert - lastLeftLength);
            
            current = leftBuf;
            leftLength = inBuffer->mDataByteSize - (bufferLengthPerConvert - lastLeftLength);
            
        }else{
            current = inBuffer->mData;
            leftLength = inBuffer->mDataByteSize;
        }
    }else{  //不足，拷贝到保留缓冲区，下次再一起处理
        memcpy(leftBuf+lastLeftLength, inBuffer->mData, bufferLengthPerConvert - lastLeftLength);
        leftLength += inBuffer->mDataByteSize;
        
        return;
    }
    
    do {
        //输入
        AudioBuffer encodeBuffer;
        encodeBuffer.mNumberChannels = inBuffer->mNumberChannels;
        encodeBuffer.mDataByteSize = (UInt32)bufferLengthPerConvert;
        encodeBuffer.mData = current;
        

        UInt32 packetPerConvert = PACKET_PER_CONVERT;
        
        //输出
        AudioBufferList outputBuffers;
        outputBuffers.mNumberBuffers = 1;
        outputBuffers.mBuffers[0].mNumberChannels =inBuffer->mNumberChannels;
        outputBuffers.mBuffers[0].mDataByteSize = outPacketLength*packetPerConvert;
        outputBuffers.mBuffers[0].mData = _convertedDataBuf;
        memset(_convertedDataBuf, 0, bufferLengthPerConvert);
        
        OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, convertDataProc, &encodeBuffer, &packetPerConvert, &outputBuffers, NULL);
        
        TFCheckStatusUnReturn(status, @"转换出错");
        
        if (current == leftBuf) {
            current = inBuffer->mData + bufferLengthPerConvert - lastLeftLength;
        }else{
            current += bufferLengthPerConvert;
        }
        leftLength -= bufferLengthPerConvert;
        
        //输出数据到下一个环节
//        NSLog(@"output buffer size:%d",outputBuffers.mBuffers[0].mDataByteSize);
        self.bufferData->bufferList = &outputBuffers;
        self.bufferData->inNumberFrames = packetPerConvert*_outputDesc.mFramesPerPacket;  //包数 * 每个包的帧数（帧数+采样率计算时长）
        [self transportAudioBuffersToNext];
        
    } while (leftLength >= bufferLengthPerConvert);
    
    if (leftLength > 0) { //有剩余，保存数据到下一次输入一起处理
        memset(leftBuf, 0, bufferLengthPerConvert);
        memcpy(leftBuf, current, leftLength);
    }
    
    TFUnrefAudioBufferData(bufferData);
}

-(void)dealloc{
    TFUnrefAudioBufferData(self.bufferData);
}

#pragma mark - call back

OSStatus convertDataProc(AudioConverterRef inAudioConverter,UInt32 *ioNumberDataPackets,AudioBufferList *ioData,AudioStreamPacketDescription **outDataPacketDescription,void *inUserData){
    
    AudioBuffer *buffer = (AudioBuffer *)inUserData;
    
    ioData->mBuffers[0].mNumberChannels = buffer->mNumberChannels;
    ioData->mBuffers[0].mData = buffer->mData;
    ioData->mBuffers[0].mDataByteSize = buffer->mDataByteSize;
    return noErr;
}


@end
