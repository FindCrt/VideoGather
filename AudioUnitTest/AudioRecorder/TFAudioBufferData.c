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
    
    return bufferData;
}

void TFRefAudioBufferData(TFAudioBufferData *bufferData){
    bufferData->refCount = bufferData->refCount + 1;
}

void TFUnrefAudioBufferData(TFAudioBufferData *bufferData){
    
    bufferData->refCount = bufferData->refCount - 1;
    if (bufferData->refCount == 0) {
        free(bufferData);
    }
}
