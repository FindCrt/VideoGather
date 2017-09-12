//
//  VRVedioEncoder.h
//  VedioRecord
//
//  Created by shiwei on 16/4/20.
//  Copyright © 2016年 施卫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface VRVideoEncoder : NSObject

-(BOOL)setupWithOutputPath:(NSString *)filePath videoSize:(CGSize)videoSize timeScale:(int)timeScale startTime:(int64_t)startTime;

-(void)encodeToH264ForPixelBuffer:(CVPixelBufferRef)pixelBuffer pts:(int64_t)pts duration:(int64_t)duration;

-(void)finishedRecording;

@end
