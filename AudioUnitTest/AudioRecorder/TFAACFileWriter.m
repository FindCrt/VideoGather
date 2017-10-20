//
//  TFAACFileWriter.m
//  VideoGather
//
//  Created by shiwei on 17/10/19.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAACFileWriter.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

/** AudioFileCreateWithURL  */

#define TFUseAVAssetWriter  1
#define TFUseAudioFile      0
#define AAC_FRAMES_NUM_PER_PACKET   1024

@interface TFAACFileWriter (){
    AudioStreamBasicDescription _audioDesc;
    
    AVAssetWriter *_writer;
    AVAssetWriterInput *_audioInput;
    
    double relativeStartTime;
    
    AudioFileID audioFile;
    UInt32 packetIndex;
}

@end

@implementation TFAACFileWriter

-(instancetype)init{
    if (self = [super init]) {
        
    }
    
    return self;
}

-(void)setFilePath:(NSString *)filePath{
    _filePath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"m4a"];
    
#if TFUseAVAssetWriter
    [self setupWriter];
#endif
    
#if TFUseAudioFile
    [self setupAudioFile];
#endif
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    _audioDesc = audioDesc;
    
#if TFUseAVAssetWriter
    [self setupWriter];
#endif
    
#if TFUseAudioFile
    [self setupAudioFile];
#endif
}

-(AudioStreamBasicDescription)audioDesc{
    return _audioDesc;
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData{
    
#if TFUseAVAssetWriter
    [self assetWriteAudioBuffers:bufferData];
#endif
    
#if TFUseAudioFile
    [self audioFileWriteAudioBuffers:bufferData];
#endif
    
}

#pragma mark - audio file

-(void)setupAudioFile{
    
    if (_audioDesc.mSampleRate == 0 || _filePath == nil) {
        return;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:_filePath];
    OSStatus status = AudioFileCreateWithURL((__bridge CFURLRef)fileURL, kAudioFileAAC_ADTSType, &(_audioDesc), kAudioFileFlags_EraseFile, &audioFile);
    TFCheckStatusUnReturn(status, @"create audio file")
    
    packetIndex = 0;
    totalSize = 0;
}

float totalSize = 0;
-(void)audioFileWriteAudioBuffers:(TFAudioBufferData *)bufferData{
    
    AudioBuffer inBuffer = bufferData->bufferList.mBuffers[0];
    AudioStreamPacketDescription packetDesc = {0, 0, inBuffer.mDataByteSize};
    UInt32 packetNum = 1;
    
    OSStatus status = AudioFileWritePackets(audioFile, NO, inBuffer.mDataByteSize, &packetDesc, packetIndex, &packetNum, inBuffer.mData);
    
    totalSize += inBuffer.mDataByteSize;
    
    
    TFCheckStatusUnReturn(status, @"write packet")
    
    packetIndex++;
}

-(void)close{
    AudioFileClose(audioFile);
    memset(&_audioDesc, 0, sizeof(_audioDesc));
    _filePath = nil;
    
    NSLog(@"%.3fM",totalSize/1024/1024);
}

#pragma mark - AVAssetWriter

-(void)setupWriter{
    
    if (_audioDesc.mSampleRate != 0 && _filePath != nil) {
        NSError *error = nil;
        _writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_filePath] fileType:AVFileTypeAppleM4A error:&error];
        
        AudioChannelLayout acl;
        bzero(&acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        
        NSDictionary *audioSettings = @{
                                        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                        AVNumberOfChannelsKey : @(_audioDesc.mChannelsPerFrame),
                                        AVSampleRateKey : @(_audioDesc.mSampleRate),
                                        AVEncoderBitRateKey : @(64000),
                                        AVChannelLayoutKey : [NSData dataWithBytes: &acl length: sizeof( acl )]
                                        };
        _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        _audioInput.expectsMediaDataInRealTime = NO;
        
        
        [_writer addInput:_audioInput];
        
        BOOL succeed = [_writer startWriting];
        [_writer startSessionAtSourceTime:[self getTimeStamp]];
        if (!succeed) {
            NSLog(@"audio writer startWriting!");
        }
    }
}

-(void)assetWriteAudioBuffers:(TFAudioBufferData *)bufferData{
    AudioBuffer inBuffer = bufferData->bufferList.mBuffers[0];
    
    CMBlockBufferRef BlockBuffer = NULL;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL, inBuffer.mData, inBuffer.mDataByteSize,kCFAllocatorNull, NULL, 0, inBuffer.mDataByteSize, kCMBlockBufferAlwaysCopyDataFlag, &BlockBuffer);
    
    TFCheckStatusUnReturn(status, @"create memory block")
    
    
    CMSampleBufferRef sampleBuffer = NULL;
    CMFormatDescriptionRef formatDescription;
    status = CMFormatDescriptionCreate ( kCFAllocatorDefault, // Allocator
                                        kCMMediaType_Audio,
                                        kAudioFormatMPEG4AAC,
                                        NULL,
                                        &formatDescription);
    TFCheckStatusUnReturn(status, @"create format description")
    CMSampleTimingInfo sampleTimingInfo = {[self getDurationFor:bufferData],[self getTimeStamp],kCMTimeInvalid };
    size_t sampleSizeInfo = inBuffer.mDataByteSize;
    
    //    NSLog(@"%lld",sampleTimingInfo.presentationTimeStamp.value);
    
    
    status = CMSampleBufferCreate(kCFAllocatorDefault, BlockBuffer, YES, NULL, NULL, formatDescription, 1, 1, &sampleTimingInfo, 1, &sampleSizeInfo, &sampleBuffer);
    
    TFCheckStatusUnReturn(status, @"create sample buffer")
    
    BOOL succeed = [_audioInput appendSampleBuffer:sampleBuffer];
    if (!succeed) {
        AVAssetWriterStatus status = _writer.status;
        NSLog(@"write audio input error!, writer status: %ld, error: %@",status, _writer.error);
    }
}

-(CMTime)getTimeStamp{
    if (relativeStartTime == 0) {
        relativeStartTime = CACurrentMediaTime();
    }
    
    double relativeTime = CACurrentMediaTime() - relativeStartTime;
    return CMTimeMakeWithSeconds(relativeTime, _audioDesc.mSampleRate);
}

-(CMTime)getDurationFor:(TFAudioBufferData *)bufferData{
    return CMTimeMake(bufferData->inNumberFrames, _audioDesc.mSampleRate);
}

@end
