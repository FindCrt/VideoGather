//
//  AUGraphMixer.h
//  VideoGather
//
//  Created by shiwei on 17/11/14.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AUGraphMixerMixType){
    AUGraphMixerMixTypeMusicLeft,
    AUGraphMixerMixTypeMusicRight,
    AUGraphMixerMixTypeMusicStereo
};

@interface AUGraphMixer : NSObject

@property (nonatomic, copy) NSString *musicFilePath;

@property (nonatomic, assign, getter=isRuning) BOOL runing;

-(void)setupAUGraph;

-(void)start;
-(void)stop;

@property (nonatomic, assign) float leftVolume;
@property (nonatomic, assign) float rightVolume;

@property (nonatomic, assign) AUGraphMixerMixType mixType;

@end
