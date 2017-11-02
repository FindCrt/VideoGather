//
//  NSString+convience.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "NSString+convience.h"

@implementation NSString (convience)

+(NSString *)timeTextFromSeconds:(NSTimeInterval)seconds{
    if (seconds < 1) {
        return [NSString stringWithFormat:@"%.2fs",seconds];
    }else if (seconds < 100*60) {
        NSInteger minutes = seconds/60;
        NSInteger sec = (NSInteger)seconds % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld",minutes,sec];
    }else{
        NSInteger minutes = seconds/60;
        NSInteger hours = minutes/60;
        NSInteger miu = (NSInteger)minutes % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld",hours,miu];
    }
}

@end
