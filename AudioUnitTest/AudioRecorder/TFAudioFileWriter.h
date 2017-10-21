//
//  TFAudioFileWriter.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioInput.h"

@interface TFAudioFileWriter : NSObject<TFAudioInput>

@property (nonatomic, assign) AudioFileTypeID fileType;

@property (nonatomic, copy) NSString *filePath;

-(void)close;

@end
