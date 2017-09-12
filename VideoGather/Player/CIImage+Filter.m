//
//  CIImage+Filter.m
//  VideoGather
//
//  Created by shiwei on 17/9/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "CIImage+Filter.h"

@implementation CIImage (Filter)

-(CIImage *)filterBy:(NSString *)filterName{
    CIFilter *filter = [CIFilter filterWithName:filterName withInputParameters:@{kCIInputImageKey : self}];
    return [filter.outputImage imageByCroppingToRect:self.extent];
}

+(CIImage *)radialGradient:(CGPoint)center radius:(CGFloat)radius{
    NSDictionary *params = @{
                                      @"inputColor0": [CIColor colorWithRed:1 green:1 blue:1],
                                      @"inputColor1": [CIColor colorWithRed:0 green:0 blue:0],
                                      @"inputCenter": [CIVector vectorWithCGPoint:center],
                                      @"inputRadius0": @(radius),
                                      @"inputRadius1": @(radius + 1)
                                      };
    return [CIFilter filterWithName:@"CIRadialGradient" withInputParameters:params].outputImage;
}

-(CIImage *)blendWithMask:(CIImage *)mask background:(CIImage *)background{
    NSDictionary *params = @{
                             kCIInputBackgroundImageKey : background,
                             kCIInputMaskImageKey : mask,
                             kCIInputImageKey : self
                             };
    return [[CIFilter filterWithName:@"CIBlendWithMask" withInputParameters:params].outputImage imageByCroppingToRect:self.extent];
}

@end
