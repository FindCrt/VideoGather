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

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSDate *createTime;
@property (nonatomic, copy) NSDate *modifyTime;
@property (nonatomic, assign) NSInteger size; //Bytes

//video audio
@property (nonatomic, assign) NSTimeInterval duration; //seconds
@property (nonatomic, assign) float rotatedDegree;
@property (nonatomic, assign) CGSize frameSize;

@end



@interface TFMediaDataAnalyzer : NSObject

+(TFMediaData *)mediaDataForItemAt:(NSString *)filePath;

@end
