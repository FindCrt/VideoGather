//
//  AUGraphMixer.h
//  VideoGather
//
//  Created by shiwei on 17/11/14.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AUGraphMixer : NSObject

@property (nonatomic, copy) NSString *musicFilePath;

@property (nonatomic, assign, getter=isRuning) BOOL runing;

-(void)setupAUGraph;

-(void)start;
-(void)stop;

@end
