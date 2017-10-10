//
//  TFAudioBufferData.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#ifndef TFAudioBufferData_h
#define TFAudioBufferData_h

#import <AudioToolbox/AudioToolbox.h>

typedef struct{
    
    AudioBufferList bufferList;
    UInt32 inNumberFrames;
    
    int refCount;
    
}TFAudioBufferData;

TFAudioBufferData *TFCreateAudioBufferData(AudioBufferList *bufferList, UInt32 inNumberFrames){
    TFAudioBufferData *bufferData = malloc(sizeof(TFAudioBufferData));
    bufferData->bufferList = &bufferList;
    bufferData->inNumberFrames = inNumberFrames;
    audioRecorder.bufferData = bufferData;

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



#endif /* TFAudioBufferData_h */
