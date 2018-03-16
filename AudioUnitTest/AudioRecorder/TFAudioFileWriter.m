//
//  TFAudioFileWriter.m
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

/* 1.ExtAudioFile 程序端数据类型必须为pcm，文件数据类型可以是其他类型，也就是它自带编码并且只处理pcm。
 * 2.property里面带client的都是只程序这一端，带file的是文件端
 * 3.AAC是压缩类型，即数据编码/压缩打包了的，固定1024个原始音频帧打成一个包。对于压缩类型，AudioStreamBasicDescription里面涉及到数据大小的类型就没有意义了。需要把这些全部设为0，否则默认值可能会是其他奇怪的内存数据,也就是使用前先置空。
 * 4.比较好奇解码后的pcm格式是怎么知道的，是否浮点、是否有符号数，还是需要变成人员自己知道编码前的格式，然后自己设置，而不是携带在AAC数据内部的？
 * 5.写完之后需要调用ExtAudioFileDispose来结束，测试结果是pcm不编码写入是不需要调用这个的，可能这个是原始流，任意取一段都是可以播放的。而AAC编码的m4a文件需要结束，这应该是文件容器本身的要求。
 */

#import "TFAudioFileWriter.h"

extern void writeNoiseToAudioFile(const char *fName,int mChannels,bool compress_with_m4a);

@interface TFAudioFileWriter (){
    TFAudioBufferData *_bufferData;
    
    ExtAudioFileRef mAudioFileRef;
    
    AudioStreamBasicDescription _audioDesc;
}

@end

@implementation TFAudioFileWriter

-(void)setFilePath:(NSString *)filePath{
    _filePath = [filePath stringByDeletingPathExtension];
    
    if ([self configureAudioFile] != 0) {
        [self close];
    }
}

-(void)setFileType:(AudioFileTypeID)fileType{
    _fileType = fileType;
    
    if ([self configureAudioFile] != 0) {
        [self close];
    }
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc{
    _audioDesc = audioDesc;
    
    if ([self configureAudioFile] != 0) {
        [self close];
    }
}

-(AudioStreamBasicDescription)audioDesc{
    return _audioDesc;
}

-(OSStatus)configureAudioFile{
    
    if (_audioDesc.mSampleRate != 0 && _fileType != 0 && _filePath != nil) {
        
        _filePath = [_filePath stringByAppendingPathExtension:[self pathExtensionForFileType:_fileType]];
        NSURL *recordFilePath = [NSURL fileURLWithPath:_filePath];
        
        if (_fileType == kAudioFileM4AType) {
            
            AudioStreamBasicDescription outputDesc;
            outputDesc.mFormatID = kAudioFormatMPEG4AAC;
            outputDesc.mFormatFlags = kMPEG4Object_AAC_Main;
            outputDesc.mChannelsPerFrame = _audioDesc.mChannelsPerFrame;
            outputDesc.mSampleRate = _audioDesc.mSampleRate;
            outputDesc.mFramesPerPacket = 1024;
            outputDesc.mBytesPerFrame = 0;
            outputDesc.mBytesPerPacket = 0;
            outputDesc.mBitsPerChannel = 0;
            outputDesc.mReserved = 0;
            
            NSString *fileDir = [recordFilePath.path stringByDeletingLastPathComponent];
            if (![[NSFileManager defaultManager] fileExistsAtPath:fileDir]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
            }
            OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef _Nonnull)(recordFilePath),_fileType, &outputDesc, NULL, kAudioFileFlags_EraseFile, &mAudioFileRef);
            TFCheckStatusReturnStatus(status, @"create ext audio file error")
            
            //输入数据格式使用这个属性设置
            UInt32 codecManf = kAppleHardwareAudioCodecManufacturer;
            status = ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManf);
            status = ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(_audioDesc), &_audioDesc);
            
            TFCheckStatusReturnStatus(status, @"ext audio file set client format");
            
            //check
            {
                AudioStreamBasicDescription fileFormat;
                UInt32 fileFmtSize = sizeof(fileFormat);
                ExtAudioFileGetProperty(mAudioFileRef, kExtAudioFileProperty_FileDataFormat, &fileFmtSize, &fileFormat);
                
                AudioStreamBasicDescription clientFormat;
                UInt32 clientFmtSize = sizeof(clientFormat);
                ExtAudioFileGetProperty(mAudioFileRef, kExtAudioFileProperty_ClientDataFormat, &clientFmtSize, &clientFormat);
                
                //fileFormat和_audioDesc一样，clientFormat和outputDesc一样
                
                AudioConverterRef converter = nil;
                UInt32 dataSize = sizeof(converter);
                ExtAudioFileGetProperty(mAudioFileRef, kExtAudioFileProperty_AudioConverter, &dataSize, &converter);
                AudioFormatListItem *formatList = nil;
                UInt32 outSize = 0;
                AudioConverterGetProperty(converter, kAudioConverterPropertyFormatList, &outSize, &formatList);
                
                UInt32 count = outSize / sizeof(AudioFormatListItem);
                for (int i = 0; i<count; i++) {
                    AudioFormatListItem format = formatList[i];
                    NSLog(@"format: %d",format.mASBD.mFormatID);
                }
            }
            
        }else if(_fileType == kAudioFileCAFType || _fileType == kAudioFileWAVEType){ //纯数据，不编码
            
            NSString *fileDir = [recordFilePath.path stringByDeletingLastPathComponent];
            if (![[NSFileManager defaultManager] fileExistsAtPath:fileDir]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            AudioStreamBasicDescription outputDesc;
            outputDesc.mFormatID = kAudioFormatLinearPCM;
            outputDesc.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
            outputDesc.mChannelsPerFrame = 2;
            outputDesc.mSampleRate = _audioDesc.mSampleRate;
            outputDesc.mFramesPerPacket = 1;
            outputDesc.mBytesPerFrame = 4;
            outputDesc.mBytesPerPacket = 4;
            outputDesc.mBitsPerChannel = 16;
            outputDesc.mReserved = 0;

            OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef _Nonnull)(recordFilePath),_fileType, &outputDesc, NULL, kAudioFileFlags_EraseFile, &mAudioFileRef);
            TFCheckStatusReturnStatus(status, @"create ext audio file error")
            
            UInt32 codecManf = kAppleHardwareAudioCodecManufacturer;
            status = ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManf);
            status = ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(_audioDesc), &_audioDesc);
            
            TFCheckStatusReturnStatus(status, @"ext audio file set client format");
            
//            UInt32 codecManf = kAppleHardwareAudioCodecManufacturer;
//            ExtAudioFileSetProperty(mAudioFileRef, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManf);
        }
    }
    
    return 0;
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
    if (!mAudioFileRef) {
        return;
    }
    _bufferData = bufferData;
    
    OSStatus status = ExtAudioFileWrite(mAudioFileRef, _bufferData->inNumberFrames, _bufferData->bufferList);
    TFCheckStatus(status, @"audio write to file")
}

-(void)close{
    ExtAudioFileDispose(mAudioFileRef);
    mAudioFileRef = nil;
}

@end
