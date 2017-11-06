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
    
    SInt64 totalFrames;
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
    
    size = sizeof(totalFrames);
    ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &size, &totalFrames);
    
    _readAviable = YES;
    
    return;
    
fail:
    [self resetReader];
}

-(void)resetReader{
    if (audioFile) {
        ExtAudioFileDispose(audioFile);
        audioFile = nil;
    }
    _readAviable = NO;
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
    
    if (self.isRepeat) {
        SInt64 curFrameOffset = 0;
        
        if (ExtAudioFileTell(audioFile, &curFrameOffset) == 0) {
            if (curFrameOffset >= totalFrames) {
                if (ExtAudioFileSeek(audioFile, 0) != 0) {
                    
                    //文件到底，回头失败，重置且返回0个frame
                    *framesNum = 0;
                    [self resetReader];
                    
                    return -1;
                }
            }
        }
    }
    
    
    OSStatus status = ExtAudioFileRead(audioFile, framesNum, &(bufferData->bufferList));
    
    TFCheckStatusUnReturn(status, @"ExtAudioFile read")
    
    if (*framesNum <= 0) {
        
        [self resetReader];
    }
    
    bufferData->inNumberFrames = *framesNum; //framesNum输入和输出可能不一致，输出是实际读取到的frame数
    
    return status;
}


@end
