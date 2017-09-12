//
//  TFMediaDataAnalyzer.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFMediaDataAnalyzer.h"

@implementation TFMediaData

@end




@implementation TFMediaDataAnalyzer

+(TFMediaData *)mediaDataForItemAt:(NSString *)filePath{
    
    TFMediaData *mediaData = [[TFMediaData alloc] init];
    mediaData.filePath = filePath;
    mediaData.filename = [[filePath lastPathComponent] stringByDeletingPathExtension];
    
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"Get attributes of file (%@) error:\n%@",filePath, error);
        return mediaData;
    }
    
    mediaData.type = [attributes objectForKey:NSFileType];
    mediaData.createTime = [attributes objectForKey:NSFileCreationDate];
    mediaData.modifyTime = [attributes objectForKey:NSFileModificationDate];
    mediaData.size = [[attributes objectForKey:NSFileSize] integerValue];
    
    //video
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];//TODO:options
    mediaData.duration = CMTimeGetSeconds(asset.duration);
    
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGAffineTransform transform = [videoTrack preferredTransform];
    
    CGFloat radians = atan2f(transform.b, transform.a);
    mediaData.rotatedDegree = radians * (180 / M_PI);
    mediaData.frameSize = [videoTrack naturalSize];
    
    return mediaData;
}

@end
