//
//  TFVideoProcessor.h
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TFVideoProcessor : NSObject

+(UIImage *)snapshotOfVideoAtPath:(NSString *)path timeScale:(float)timeScale;
+(UIImage *)snapshotOfVideoAtPath:(NSString *)path time:(NSTimeInterval)time;

@end
