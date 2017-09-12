//
//  TFVideoProcessor.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFVideoProcessor.h"
#import <AVFoundation/AVFoundation.h>

@implementation TFVideoProcessor

+(UIImage *)snapshotOfVideoAtPath:(NSString *)path timeScale:(float)timeScale{
    
    NSAssert(timeScale >= 0 && timeScale <= 1, @"timeScale out range of [0,1]");
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    
    NSError *error = nil;
    CGImageRef imgeRef = [imageGenerator copyCGImageAtTime:CMTimeMultiply(asset.duration, timeScale) actualTime:nil error:&error];
    if (error) {
        NSLog(@"AssetImageGenerator copy image from (%@) error:\n%@",path, error);
        return nil;
    }
    
    return [UIImage imageWithCGImage:imgeRef];
}

+(UIImage *)snapshotOfVideoAtPath:(NSString *)path time:(NSTimeInterval)time{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
    if (time > CMTimeGetSeconds(asset.duration) || time < 0) {
        return nil;
    }
    return [self snapshotOfVideoAtPath:path timeScale:time/CMTimeGetSeconds(asset.duration)];
}

@end
