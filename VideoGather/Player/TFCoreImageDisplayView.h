//
//  TFCoreImageDisplayView.h
//  VideoGather
//
//  Created by shiwei on 17/9/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>

@interface TFCoreImageDisplayView : GLKView



@property (nonatomic, strong) CIImage *image;

@end
