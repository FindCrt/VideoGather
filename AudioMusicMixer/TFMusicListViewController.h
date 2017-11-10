//
//  TFMusicListViewController.h
//  VideoGather
//
//  Created by shiwei on 17/11/2.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFMediaDataAnalyzer.h"

@interface TFMusicListViewController : UITableViewController

@property (nonatomic, copy) NSString *rootDirectory;

@property (nonatomic, copy) void (^selectMusicConpletionHandler)(TFMediaData *music);

@end
