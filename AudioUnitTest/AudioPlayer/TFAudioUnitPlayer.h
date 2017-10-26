//
//  TFAudioUnitPlayer.h
//  VideoGather
//
//  Created by shiwei on 17/10/25.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TFStatusChecker.h"
//#import "TFAudioInput.h"

@interface TFAudioUnitPlayer : NSObject

-(void)playLocalFile:(NSString *)filePath;

-(void)playPCMBuffer:(void *)buffer;

-(void)stop;

@end
