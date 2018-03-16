//
//  AUGraphMixer.h
//  VideoGather
//
//  Created by shiwei on 17/11/14.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AUGraphMixerChannelType){
    AUGraphMixerChannelTypeLeft,
    AUGraphMixerChannelTypeRight,
    AUGraphMixerChannelTypeStereo
};

@interface AUGraphMixer : NSObject

@property (nonatomic, copy) NSString *musicFilePath;

@property (nonatomic, copy) NSString *musicFilePath2;

@property (nonatomic, copy) NSString *outputPath;

@property (nonatomic, assign, getter=isRuning) BOOL runing;

-(void)setupAUGraph;

-(void)start;
-(void)stop;

//设置输入源的音量，index是mixer的输入源的索引
-(void)setVolumeAtIndex:(NSInteger)index to:(float)volume;

//设置输入源的声道类型，index是mixer的输入源的索引
-(void)setAudioSourceAtIndex:(NSInteger)index channelTypeTo:(AUGraphMixerChannelType)channelType;

-(AUGraphMixerChannelType)channelTypeForSourceAt:(NSInteger)index;

@end
