//
//  TFMediaDataAnalyzer.h
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface TFMediaData : NSObject

@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, assign) BOOL isAudio;

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSDate *createTime;
@property (nonatomic, copy) NSDate *modifyTime;
@property (nonatomic, assign) NSInteger size; //Bytes
@property (nonatomic, copy) NSString *fileExtension;

//video audio
@property (nonatomic, assign) NSTimeInterval duration; //seconds
@property (nonatomic, assign) float rotatedDegree;
@property (nonatomic, assign) CGSize frameSize;
@property (nonatomic, strong) UIImage *coverImage; //封面图
@property (nonatomic, copy) NSString *author;

@end



@interface TFMediaDataAnalyzer : NSObject

+(TFMediaData *)mediaDataForItemAt:(NSString *)filePath;

@end
