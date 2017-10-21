//
//  ExtAudioFileMixer.h
//  AudioManager
//
//  Created by zeng songgen on 12-8-7.
//  Copyright (c) 2012年 Rumtel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExtAudioFileMixer : NSObject

+ (OSStatus)mixAudio:(NSString *)audioPath1
            andAudio:(NSString *)audioPath2
              toFile:(NSString *)outputPath
  preferedSampleRate:(float)sampleRate;

@end
