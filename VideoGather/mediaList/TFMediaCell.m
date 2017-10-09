//
//  TFMediaCell.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFMediaCell.h"
#import "NSString+convience.h"
#import "TFVideoProcessor.h"


@interface TFMediaCell ()<UIAlertViewDelegate>{
    UIImageView *_imageView;
    
    UILabel *_nameLabel;
    UILabel *_timeLabel;
    UILabel *_durationLabel;
    
    UILongPressGestureRecognizer *_longPress;
}

@end

@implementation TFMediaCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        [self addSubview:_imageView];
        
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.frame.size.height - 60, 200, 20)];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.font = [UIFont systemFontOfSize:16];
        _nameLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_nameLabel];

        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.frame.size.height - 40, 200, 15)];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.font = [UIFont systemFontOfSize:13];
        _timeLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_timeLabel];
        
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.frame.size.height - 25, 160, 15)];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont systemFontOfSize:13];
        _durationLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_durationLabel];
        
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(delegateMedia:)];
        [self addGestureRecognizer:_longPress];
    }
    
    return self;
}

-(void)setMedia:(TFMediaData *)media{
    _media = media;
    
    if (media.isVideo) {
        _imageView.image = [TFVideoProcessor snapshotOfVideoAtPath:media.filePath time:0.4];
    }else{
        _imageView.image = [UIImage imageNamed:@"audio"];
        _imageView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
    }

    _nameLabel.text = media.filename;
    _timeLabel.text = [NSString stringWithFormat:@"%@",media.createTime];
    _durationLabel.text = [NSString stringWithFormat:@"%@  %.2fM",[NSString timeTextFromSeconds:media.duration],media.size/1024.0f/1024.0f];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    _imageView.frame = self.bounds;
}

-(void)delegateMedia:(UILongPressGestureRecognizer *)longPress{
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:nil delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Delete", @"transport",nil];
        [alertView show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        if ([self.delegate respondsToSelector:@selector(mediaCell:deleteMedia:)]) {
            [self.delegate mediaCell:self deleteMedia:self.media];
        }
    }else if (buttonIndex == 2){
        if ([self.delegate respondsToSelector:@selector(mediaCell:shareMedia:)]) {
            [self.delegate mediaCell:self shareMedia:self.media];
        }
    }
}

+(CGFloat)heightForMedia:(TFMediaData *)media{
    if (media.isVideo) {
        return 200;
    }else{
        return 70;
    }
}

@end
