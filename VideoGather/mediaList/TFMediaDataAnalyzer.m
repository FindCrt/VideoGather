//
//  TFMediaDataAnalyzer.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFMediaDataAnalyzer.h"
#import <UIKit/UIKit.h>

@implementation TFMediaData

-(NSString *)fileExtension{
    return [_filePath pathExtension];
}

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
    
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];//TODO:options
    mediaData.duration = CMTimeGetSeconds(asset.duration);
    
    for (NSString *metadataFmt in [asset availableMetadataFormats]) {
        
//        if ([metadataFmt isEqualToString:AVMetadataCommonKeyArtwork]) {
        
            NSArray *metaDatas = [asset metadataForFormat:metadataFmt];
        for (AVMetadataItem *item in metaDatas) {
            
            if ([item.commonKey isEqualToString:AVMetadataCommonKeyArtwork]) {
                mediaData.coverImage = [UIImage imageWithData:(NSData *)item.value];
            }else if ([item.commonKey isEqualToString:AVMetadataCommonKeyAuthor]){
                mediaData.author = (NSString *)item.value;
            }
        }

//        }
    }
    
    //video
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    if (videoTrack) {
        mediaData.isVideo = YES;
        
        CGAffineTransform transform = [videoTrack preferredTransform];
        
        CGFloat radians = atan2f(transform.b, transform.a);
        mediaData.rotatedDegree = radians * (180 / M_PI);
        mediaData.frameSize = [videoTrack naturalSize];
    }else if(audioTrack){
        
        mediaData.isAudio = YES;
    }
    
    return mediaData;
}

@end
