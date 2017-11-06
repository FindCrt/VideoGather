//
//  TFMediaListViewController.h
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TFMediaData;
typedef void(^TFMediaSelectedHandler)(TFMediaData *mediaData);

@interface TFMediaListViewController : UIViewController

@property (nonatomic, copy) NSString *mediaDir;

@property (nonatomic, copy) TFMediaSelectedHandler selectHandler;

@property (nonatomic, copy) void(^disappearHandler)();

@end
