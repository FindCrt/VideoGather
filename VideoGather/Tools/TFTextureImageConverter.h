//
//  TFTextureImageConverter.h
//  VideoGather
//
//  Created by shiwei on 17/9/30.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>
#import <CoreGraphics/CoreGraphics.h>

@interface TFTextureImageConverter : NSObject

+(GLuint )createTextureFromImage:(NSString *)imgName;

@end
