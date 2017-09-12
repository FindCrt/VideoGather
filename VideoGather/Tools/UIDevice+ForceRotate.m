//
//  UIDevice+ForceRotate.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "UIDevice+ForceRotate.h"

@implementation UIDevice (ForceRotate)

+(void)changeOrientation:(UIDeviceOrientation)orientation{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selecor = NSSelectorFromString(@"setOrientation:");
        NSMethodSignature *signature = [UIDevice instanceMethodSignatureForSelector:selecor];
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = [UIDevice currentDevice];
        invocation.selector = selecor;
        [invocation setArgument:&orientation atIndex:2];
        
        [invocation invoke];
    }
}

@end
