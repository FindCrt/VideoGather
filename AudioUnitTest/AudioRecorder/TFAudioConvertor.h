//
//  TFAudioConvertor.h
//  VideoGather
//
//  Created by shiwei on 17/10/9.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioInput.h"
#import "TFAudioOutput.h"

@interface TFAudioConvertor : TFAudioOutput<TFAudioInput>

@property (nonatomic, assign) AudioFormatID outputFormat;

@end
