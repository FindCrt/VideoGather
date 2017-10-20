//
//  TFAudioFileWriter.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioFileWriter.h"

@interface TFAudioFileWriter (){
    TFAudioBufferData *_bufferData;
    
    ExtAudioFileRef mAudioFileRef;
    
    AudioStreamBasicDescription _audioDesc;
}

@end

@implementation TFAudioFileWriter

-(void)setFilePath:(NSString *)filePath{
    _filePath = [filePath stringByDeletingPathExtension];
    
    [self configureAudioFile];
}

-(void)setFileType:(AudioFileTypeID)fileType{
    _fileType = fileType;
    
    [self configureAudioFile];
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    _audioDesc = audioDesc;
    
    [self configureAudioFile];
}

-(AudioStreamBasicDescription)audioDesc{
    return _audioDesc;
}

-(void)configureAudioFile{
    
    if (_audioDesc.mSampleRate != 0 && _fileType != 0 && _filePath != nil) {
        
        _filePath = [_filePath stringByAppendingPathExtension:[self pathExtensionForFileType:_fileType]];
        NSURL *recordFilePath = [NSURL fileURLWithPath:_filePath];
        
        if (_fileType == kAudioFileM4AType) {
            
            AudioStreamBasicDescription outputDesc;
            outputDesc.mFormatID = kAudioFormatMPEG4AAC;
            outputDesc.mChannelsPerFrame = _audioDesc.mChannelsPerFrame;
            outputDesc.mSampleRate = _audioDesc.mSampleRate;
//            outputDesc.mFramesPerPacket = 1024;
            
            OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef _Nonnull)(recordFilePath),_fileType, &outputDesc, NULL, kAudioFileFlags_EraseFile, &mAudioFileRef);
            TFCheckStatus(status, @"create ext audio file error")
            
            //输入数据格式使用这个属性设置
            UInt32 codecManf = kAppleSoftwareAudioCodecManufacturer;
            status = ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManf);
            status = ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(_audioDesc), &_audioDesc);
            
            TFCheckStatusUnReturn(status, @"ext audio file set client format");
            
            //check
            {
                AudioConverterRef converter;
                UInt32 dataSize = sizeof(converter);
                ExtAudioFileGetProperty(mAudioFileRef, kExtAudioFileProperty_AudioConverter, &dataSize, &converter);
                AudioFormatListItem *formatList;
                UInt32 outSize = 0;
                AudioConverterGetProperty(converter, kAudioConverterPropertyFormatList, &outSize, &formatList);
                
                UInt32 count = outSize / sizeof(AudioFormatListItem);
                for (int i = 0; i<count; i++) {
                    AudioFormatListItem format = formatList[i];
                    
                }
            }
            
        }else if(_fileType == kAudioFileCAFType || _fileType == kAudioFileWAVEType){ //纯数据，不编码
            
            OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef _Nonnull)(recordFilePath),_fileType, &_audioDesc, NULL, kAudioFileFlags_EraseFile, &mAudioFileRef);
            TFCheckStatus(status, @"create ext audio file error")
            
            UInt32 codecManf = kAppleHardwareAudioCodecManufacturer;
            ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManf);
        }
        
        
//        ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_FileMaxPacketSize, sizeof(UInt32), &codecManf);
        
        
    }
}

-(NSString *)pathExtensionForFileType:(AudioFileTypeID)fileType{
    switch (fileType) {
        case kAudioFileM4AType:
            return @"m4a";
            break;
        case kAudioFileWAVEType:
            return @"wav";
            break;
        case kAudioFileCAFType:
            return @"caf";
            break;
            
        default:
            break;
    }
    
    return nil;
}

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData{
    //NSLog(@"file writer in buffer");
    _bufferData = bufferData;
    
    OSStatus status = ExtAudioFileWrite(mAudioFileRef, _bufferData->inNumberFrames, &_bufferData->bufferList);
    TFCheckStatus(status, @"audio write to file")
}

@end
