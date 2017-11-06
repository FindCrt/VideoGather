//
//  TFAudioFileReader.m
//  VideoGather
//
//  Created by shiwei on 17/11/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioFileReader.h"

@interface TFAudioFileReader (){
    ExtAudioFileRef audioFile;
    
    AudioStreamBasicDescription fileDesc;
    UInt32 packetSize;
    
    Float64 _desireSampleRate;
}

@end

@implementation TFAudioFileReader

-(void)setFilePath:(NSString *)filePath{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
        NSLog(@"audio play: no file at: %@",filePath);
        return;
    }
    
    _filePath = filePath;
    
    [self setupExtAudioFileReader];
}

-(void)setupExtAudioFileReader{
    
    NSURL *fileURL = [NSURL fileURLWithPath:_filePath];
    OSStatus status = ExtAudioFileOpenURL((__bridge CFURLRef)fileURL, &audioFile);
    
    TFCheckStatusGoToFail(status, ([NSString stringWithFormat:@"open ExtAudioFile: %@",_filePath]))
    
    UInt32 size = sizeof(fileDesc);
    status = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &size, &fileDesc);
    
    TFCheckStatusGoToFail(status, @"ExtAudioFile get file format")
    
    //read with pcm format
    if (_desireSampleRate == 0) {
        _outputDesc.mSampleRate = fileDesc.mSampleRate;
    }
    _outputDesc.mFormatID = kAudioFormatLinearPCM;
    _outputDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _outputDesc.mReserved = 0;
    _outputDesc.mChannelsPerFrame = 1; //2
    _outputDesc.mBitsPerChannel = 16;
    _outputDesc.mFramesPerPacket = 1;
    _outputDesc.mBytesPerFrame = _outputDesc.mChannelsPerFrame * _outputDesc.mBitsPerChannel / 8;
    _outputDesc.mBytesPerPacket = _outputDesc.mBytesPerFrame;
    
    size = sizeof(_outputDesc);
    status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, size, &_outputDesc);
    
    size = sizeof(packetSize);
    ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_ClientMaxPacketSize, &size, &packetSize);
    NSLog(@"read pcm packet/frame size: %d",(unsigned int)packetSize);
    
    TFCheckStatusGoToFail(status, @"ExtAudioFile set client format")
    
    _readAviable = YES;
    
    return;
    
fail:
    [self resetAudioFile];
    _readAviable = NO;
}

-(void)resetAudioFile{
    if (audioFile) {
        ExtAudioFileDispose(audioFile);
        audioFile = nil;
    }
}

-(BOOL)setDesireSampleRate:(Float64)desireSampleRate{
    _desireSampleRate = desireSampleRate;
    
    if (_readAviable && _outputDesc.mSampleRate != desireSampleRate) {
        
        _outputDesc.mSampleRate = desireSampleRate;
        UInt32 size = sizeof(_outputDesc);
        OSStatus status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, size, &_outputDesc);
        
        return status == 0;
    }else{
        _outputDesc.mSampleRate = desireSampleRate;
    }

    return YES;
}

-(OSStatus)readFrames:(UInt32 *)framesNum toBufferData:(TFAudioBufferData *)bufferData{
    
    if (!_readAviable) {
        return -1;
    }
    
    NSAssert(audioFile, @"audioFileReader file uninstall!");
    
    OSStatus status = ExtAudioFileRead(audioFile, framesNum, &(bufferData->bufferList));
    bufferData->inNumberFrames = *framesNum; //framesNum输入和输出可能不一致，输出是实际读取到的frame数
    
    TFCheckStatusUnReturn(status, @"ExtAudioFile read")
    
    if (*framesNum <= 0) {
        
        if (self.isRepeat) {
            
            //return to file head, and read again
            ExtAudioFileSeek(audioFile, 0);
            [self readFrames:framesNum toBufferData:bufferData];
            
        }else{
            _readAviable = NO;
            memset(bufferData->bufferList.mBuffers[0].mData, 0, bufferData->bufferList.mBuffers[0].mDataByteSize);
            
            [self resetAudioFile];
        }
    }
    
    return status;
}


@end
