//
//  TFVideoTransfer.h
//  VideoGather
//
//  Created by shiwei on 17/9/11.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface TFVideoTransfer : NSObject

-(void)transferVideo:(CMSampleBufferRef)sampleBuffer;

@end
