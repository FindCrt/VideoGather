//
//  TFAudioInput.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioBufferData.h"
#import "TFStatusChecker.h"

@protocol TFAudioInput <NSObject>

-(void)setAudioDesc:(AudioStreamBasicDescription)audioDesc;
-(AudioStreamBasicDescription)audioDesc;

-(void)receiveNewAudioBuffers:(TFAudioBufferData *)bufferData;

@end
