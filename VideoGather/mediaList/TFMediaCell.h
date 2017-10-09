//
//  TFMediaCell.h
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFMediaDataAnalyzer.h"

@class TFMediaCell;
@protocol TFMediaCellDelegate <NSObject>

-(void)mediaCell:(TFMediaCell *)cell deleteMedia:(TFMediaData *)media;
-(void)mediaCell:(TFMediaCell *)cell shareMedia:(TFMediaData *)media;

@end

@interface TFMediaCell : UITableViewCell

@property (nonatomic, weak) id<TFMediaCellDelegate> delegate;

@property (nonatomic, strong) TFMediaData *media;

+(CGFloat)heightForMedia:(TFMediaData *)media;

@end
