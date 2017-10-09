//
//  TFAudioInput.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioBufferData.h"

@protocol TFAudioInput <NSObject>

#define TFCheckStatus(status, log)    if(status != 0) {\
int bigEndian = CFSwapInt32HostToBig(status);\
char *statusTex = (char*)&bigEndian;\
NSLog(@"%@ error: %s",log,statusTex); return;\
}

#define TFCheckError(error, log)    if(error) {\
NSLog(@"%@ error:\n{%@}",log,error); return;\
}

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc;
-(AudioStreamBasicDescription)audioDesc;

-(void)receiveNewAudioBuffers:(TFAudioBufferData )bufferData;

@end
