//
//  TFCoreImageDisplayView.m
//  VideoGather
//
//  Created by shiwei on 17/9/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFCoreImageDisplayView.h"

@interface TFCoreImageDisplayView (){
    EAGLContext *_glContext;
    CIContext *_coreImageContext;
}

@end

@implementation TFCoreImageDisplayView

-(instancetype)initWithFrame:(CGRect)frame{
    EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES3)];
    
    return [self initWithFrame:frame context:glContext];
}

-(instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context{
    if (self = [super initWithFrame:frame context:context]) {
        _coreImageContext = [CIContext contextWithEAGLContext:context];
        
        self.enableSetNeedsDisplay = NO;
    }
    
    return self;
}

-(void)setImage:(CIImage *)image{
    _image = image;
    [self display];
}

-(void)drawRect:(CGRect)rect{
    if (_image) {
        
        CGFloat scale = self.window ? self.window.screen.scale : 1.0;
        rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(scale, scale));
        [_coreImageContext drawImage:_image inRect:rect fromRect:_image.extent];
    }
}

@end
