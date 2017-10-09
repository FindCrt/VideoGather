//
//  TFAudioFileWriter.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAudioFileWriter.h"

@interface TFAudioFileWriter (){
    TFAudioBufferData _bufferData;
    
    ExtAudioFileRef mAudioFileRef;
    
    AudioStreamBasicDescription _audioDesc;
}

@end

@implementation TFAudioFileWriter

-(void)setFilePath:(NSString *)filePath{
    _filePath = [filePath stringByDeletingPathExtension];
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
    //export file
    _filePath = [_filePath stringByAppendingPathExtension:[self pathExtensionForFileType:_fileType]];
    NSURL *recordFilePath = [NSURL fileURLWithPath:_filePath];
    
    OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef _Nonnull)(recordFilePath),_fileType, &_audioDesc, NULL, kAudioFileFlags_EraseFile, &mAudioFileRef);
    TFCheckStatus(status, @"create ext audio file error")
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

-(void)receiveNewAudioBuffers:(TFAudioBufferData)bufferData{
    _bufferData = bufferData;
    
    OSStatus status = ExtAudioFileWrite(mAudioFileRef, _bufferData.inNumberFrames, _bufferData.bufferList);
    TFCheckStatus(status, @"audio write to file")
}

@end
