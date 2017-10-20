//
//  TFAACFileWriter.h
//  VideoGather
//
//  Created by shiwei on 17/10/19.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFAudioInput.h"

@interface TFAACFileWriter : NSObject<TFAudioInput>

@property (nonatomic, copy) NSString *filePath;

-(void)close;

@end
