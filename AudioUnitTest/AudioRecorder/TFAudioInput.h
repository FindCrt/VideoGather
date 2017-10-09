//
//  TFAudioInput.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol TFAudioInput <NSObject>

#define TFCheckStatus(status, log)    if(status != 0) {\
int bigEndian = CFSwapInt32HostToBig(status);\
char *statusTex = (char*)&bigEndian;\
NSLog(@"%@ error: %s",log,statusTex); return;\
}

#define TFCheckError(error, log)    if(error) {\
NSLog(@"%@ error:\n{%@}",log,error); return;\
}

-(void)setAudioDescription:(AudioStreamBasicDescription)audioDesc;
-(AudioStreamBasicDescription)audioDesc;

-(void)receiveNewAudioBuffers:(AudioBufferList *)bufferList;

-(void)processBuffer;

@end
