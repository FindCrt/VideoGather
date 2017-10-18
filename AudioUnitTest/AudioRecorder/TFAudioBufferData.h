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

TFAudioBufferData *TFCreateAudioBufferData(AudioBufferList *bufferList, UInt32 inNumberFrames);
void TFRefAudioBufferData(TFAudioBufferData *bufferData);
void TFUnrefAudioBufferData(TFAudioBufferData *bufferData);


#endif /* TFAudioBufferData_h */
