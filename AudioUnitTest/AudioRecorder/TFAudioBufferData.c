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
    if (bufferList) bufferData->bufferList = *bufferList;
    bufferData->inNumberFrames = inNumberFrames;
    bufferData->refCount = 1;
    
    return bufferData;
}

TFAudioBufferData *TFAllocAudioBufferData(AudioStreamBasicDescription audioDesc, UInt32 inNumberFrames){
    AudioBuffer buffer;
    int numberSamples = inNumberFrames * audioDesc.mChannelsPerFrame;
    buffer.mDataByteSize = numberSamples * audioDesc.mBitsPerChannel/8;
    buffer.mNumberChannels = audioDesc.mChannelsPerFrame;
    buffer.mData = malloc( buffer.mDataByteSize ); // buffer size
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    return TFCreateAudioBufferData(&bufferList, inNumberFrames);
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
        
        printf("free buffer data\n");
        free(bufferData);
    }
}
