//
//  TFAudioBufferData.c
//  VideoGather
//
//  Created by shiwei on 17/10/13.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#include <stdio.h>
#include "TFAudioBufferData.h"

extern void writeNoiseToAudioFile(const char *fName,int mChannels,bool compress_with_m4a);

TFAudioBufferData *TFCreateAudioBufferData(AudioBufferList *bufferList, UInt32 inNumberFrames){
    TFAudioBufferData *bufferData = (TFAudioBufferData*)malloc(sizeof(TFAudioBufferData));
    if (bufferList) bufferData->bufferList = bufferList;
    bufferData->inNumberFrames = inNumberFrames;
    bufferData->refCount = 1;
    
    return bufferData;
}

TFAudioBufferData *TFAllocAudioBufferData(AudioStreamBasicDescription audioDesc, UInt32 inNumberFrames){
    
    AudioBufferList *bufferList = malloc(sizeof(AudioBufferList));
    bool isNonInterleaved = audioDesc.mFormatFlags & kAudioFormatFlagIsNonInterleaved;
    if (isNonInterleaved) {
        bufferList->mNumberBuffers = 2;
        
        bufferList->mBuffers[0].mDataByteSize = inNumberFrames *
        audioDesc.mBytesPerFrame;
        bufferList->mBuffers[0].mNumberChannels = 1;
        bufferList->mBuffers[0].mData = malloc( bufferList->mBuffers[0].mDataByteSize ); // buffer size
        
        bufferList->mBuffers[1].mDataByteSize = bufferList->mBuffers[0].mDataByteSize;
        bufferList->mBuffers[1].mNumberChannels = bufferList->mBuffers[0].mNumberChannels;
        bufferList->mBuffers[1].mData = malloc( bufferList->mBuffers[0].mDataByteSize );
        
        memset(bufferList->mBuffers[0].mData, 0, bufferList->mBuffers[0].mDataByteSize);
        memset(bufferList->mBuffers[1].mData, 0, bufferList->mBuffers[0].mDataByteSize);
        
    }else{
        
        bufferList->mNumberBuffers = 1;
        
        bufferList->mBuffers[0].mDataByteSize = inNumberFrames *
        audioDesc.mBytesPerFrame;
        bufferList->mBuffers[0].mNumberChannels = audioDesc.mChannelsPerFrame;
        bufferList->mBuffers[0].mData = malloc( bufferList->mBuffers[0].mDataByteSize ); // buffer size
    }
    
    return TFCreateAudioBufferData(bufferList, inNumberFrames);
}

void TFRefAudioBufferData(TFAudioBufferData *bufferData){
    bufferData->refCount = bufferData->refCount + 1;
}

void TFCopyAudioBufferData(TFAudioBufferData **srcBufferData, TFAudioBufferData **destBufferData){
    (*srcBufferData)->refCount = (*srcBufferData)->refCount +1;
    *destBufferData = *srcBufferData;
}

void TFUnrefAudioBufferData(TFAudioBufferData *bufferData){
    
    bufferData->refCount = bufferData->refCount - 1;
    if (bufferData->refCount == 0) {
        
//        printf("free buffer data\n");
        free(bufferData);
    }
}
