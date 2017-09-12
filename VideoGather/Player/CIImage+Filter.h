//
//  CIImage+Filter.h
//  VideoGather
//
//  Created by shiwei on 17/9/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface CIImage (Filter)

-(CIImage *)filterBy:(NSString *)filterName;

+(CIImage *)radialGradient:(CGPoint)center radius:(CGFloat)radius;

-(CIImage *)blendWithMask:(CIImage *)mask background:(CIImage *)background;

@end
