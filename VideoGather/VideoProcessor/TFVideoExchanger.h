//
//  TFVideoExchanger.h
//  VideoGather
//
//  Created by shiwei on 17/9/6.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TFVideoExchanger : NSObject

@property (nonatomic, copy) NSString *filePath;

-(void)startExchange;

@end
