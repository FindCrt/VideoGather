//
//  TFVideoNormalControlView.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFVideoNormalControlView.h"
#import "NSString+convience.h"

#define TFControlSpace  10
#define TFForwardInterval 5.0f
#define TFBackInterval  2.0f

@interface TFVideoNormalControlView (){
    UIButton *_playPauseBtn;
    UIButton *_extendButton;
    UIButton *_changeRateBtn; //播放速度
    UISlider *_changeRateSlider;
    
    UISlider *_progressSlider;
    UILabel *_curTimeLabel;
    UILabel *_durationLabel;
    BOOL _justUIChange;
    
    UISwipeGestureRecognizer *_swipeRight;
    UISwipeGestureRecognizer *_swipeLeft;
    
    NSTimeInterval _duration;
}

@end

@implementation TFVideoNormalControlView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self commonInit];
    }
    
    return self;
}

-(void)commonInit{
    _changeRateBtn = [[UIButton alloc] init];
    [_changeRateBtn setTitle:@"rate" forState:(UIControlStateNormal)];
    [_changeRateBtn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    _changeRateBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    _changeRateBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _changeRateBtn.layer.borderWidth = 0.5f;
    [_changeRateBtn addTarget:self action:@selector(showChangeRateSlider:) forControlEvents:(UIControlEventTouchUpInside)];
    [self addSubview:_changeRateBtn];
    
    _changeRateSlider = [[UISlider alloc] init];
    _changeRateSlider.maximumValue = 3;
    _changeRateSlider.minimumValue = -2;
    _changeRateSlider.hidden = YES;
    _changeRateSlider.value = 1.0f;
    _changeRateSlider.transform = CGAffineTransformMakeRotation(M_PI_2);
    [_changeRateSlider addTarget:self action:@selector(changePlayRate:) forControlEvents:(UIControlEventValueChanged)];
    [self addSubview:_changeRateSlider];

    _playPauseBtn = [[UIButton alloc] init];
    [_playPauseBtn setImage:[UIImage imageNamed:@"play"] forState:(UIControlStateNormal)];
    [_playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:(UIControlStateSelected)];
    [_playPauseBtn addTarget:self action:@selector(playPause:) forControlEvents:(UIControlEventTouchUpInside)];
    [self addSubview:_playPauseBtn];
    
    _extendButton = [[UIButton alloc] init];
    [_extendButton setImage:[UIImage imageNamed:@"extend"] forState:(UIControlStateNormal)];
    [_extendButton setImage:[UIImage imageNamed:@"shrink"] forState:(UIControlStateSelected)];
    [_extendButton addTarget:self action:@selector(extendOrShrinkFullScreen:) forControlEvents:(UIControlEventTouchUpInside)];
    [self addSubview:_extendButton];
    
    _curTimeLabel = [[UILabel alloc] init];
    _curTimeLabel.textColor = [UIColor whiteColor];
    _curTimeLabel.font = [UIFont systemFontOfSize:12];
    [self addSubview:_curTimeLabel];
    
    _durationLabel = [[UILabel alloc] init];
    _durationLabel.textColor = [UIColor whiteColor];
    _durationLabel.font = [UIFont systemFontOfSize:12];
    [self addSubview:_durationLabel];
    
    _progressSlider = [[UISlider alloc] init];
    [_progressSlider addTarget:self action:@selector(changeProgress:) forControlEvents:(UIControlEventTouchUpInside)];
    [self addSubview:_progressSlider];
    
    
    
    //TODO:手势的工作原理
    _swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeView:)];
    [self addGestureRecognizer:_swipeRight];
    _swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeView:)];
    _swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:_swipeLeft];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat bottomLine = self.frame.size.height - 25;
    CGFloat buttonWidth = 30;
    CGFloat sliderHeight = 24;
    CGFloat labelHeight = 20;
    
    _playPauseBtn.frame = CGRectMake(TFControlSpace, bottomLine - buttonWidth/2.0, buttonWidth, buttonWidth);
    _extendButton.frame = CGRectMake(self.frame.size.width - buttonWidth - TFControlSpace, bottomLine - buttonWidth/2.0, buttonWidth, buttonWidth);
    
    _curTimeLabel.frame = CGRectMake(CGRectGetMaxX(_playPauseBtn.frame)+TFControlSpace, bottomLine - labelHeight/2.0, 40, 20);
    _durationLabel.frame = CGRectMake(CGRectGetMinX(_extendButton.frame) - TFControlSpace - 40,bottomLine - labelHeight/2.0, 40, 20);
    
    _progressSlider.frame = CGRectMake(CGRectGetMaxX(_curTimeLabel.frame), bottomLine - sliderHeight/2.0, CGRectGetMinX(_durationLabel.frame) - CGRectGetMaxX(_curTimeLabel.frame), sliderHeight);
    
    _changeRateBtn.frame = CGRectMake(self.frame.size.width - 80, TFControlSpace, 40, 24);
    _changeRateSlider.frame = CGRectMake(CGRectGetMinX(_changeRateBtn.frame), CGRectGetMaxY(_changeRateBtn.frame), buttonWidth, self.frame.size.height - CGRectGetMaxY(_changeRateBtn.frame) - TFControlSpace);
}

#pragma mark - control actions

-(void)playPause:(UIButton *)button{
    button.selected = !button.selected;
    
    if (button.selected) {
        if ([self.controlDelegate respondsToSelector:@selector(play)]) {
            [self.controlDelegate play];
        }
    }else{
        if ([self.controlDelegate respondsToSelector:@selector(pause)]) {
            [self.controlDelegate pause];
        }
    }
}

-(void)extendOrShrinkFullScreen:(UIButton *)button{
    button.selected = !button.selected;
    
    if (button.selected) {
        if ([self.screenDelegate respondsToSelector:@selector(extendToFullScreen)]) {
            [self.screenDelegate extendToFullScreen];
        }
    }else{
        if ([self.screenDelegate respondsToSelector:@selector(shrinkFromFullScreen)]) {
            [self.screenDelegate shrinkFromFullScreen];
        }
    }
}

-(void)showChangeRateSlider:(UIButton *)button{
    button.selected = !button.selected;
    
    if (button.selected) {
        _changeRateSlider.hidden = NO;
        
    }else{
        _changeRateSlider.hidden = YES;
        
        if ([self.controlDelegate respondsToSelector:@selector(changePlayRate:)]) {
            [self.controlDelegate changePlayRate:_changeRateSlider.value];
        }
    }
}

-(void)changePlayRate:(UISlider *)slider{
    
    NSString *rateText = @"rate";
    if (_changeRateSlider.value != 1.0) {
        rateText = [NSString stringWithFormat:@"x%.1f",_changeRateSlider.value];
        [_changeRateBtn setTitleColor:[UIColor orangeColor] forState:(UIControlStateNormal)];
    }else{
        [_changeRateBtn setTitleColor:[UIColor clearColor] forState:(UIControlStateNormal)];
    }
    [_changeRateBtn setTitle:rateText forState:(UIControlStateNormal)];
}

-(void)changeProgress:(UISlider *)slider{
    if (_justUIChange) {
        return;
    }
    if ([self.controlDelegate respondsToSelector:@selector(skipToProgress:)]) {
        [self.controlDelegate skipToProgress:slider.value];
    }
}

-(void)swipeView:(UISwipeGestureRecognizer *)swipe{

    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        if ([self.controlDelegate respondsToSelector:@selector(goForwardWithTimeInterval:)]) {
            [self.controlDelegate goForwardWithTimeInterval:TFForwardInterval];
        }
    }else if(swipe.direction == UISwipeGestureRecognizerDirectionLeft){
        if ([self.controlDelegate respondsToSelector:@selector(goBackWithTimeInterval:)]) {
            [self.controlDelegate goBackWithTimeInterval:TFBackInterval];
        }
    }
}

#pragma mark - UI change as player status change.

-(void)UIChangeByplay{
    _playPauseBtn.selected = YES;
}

-(void)UIChangeBypause{
    _playPauseBtn.selected = NO;
}

-(void)UIChangeByGetDuration:(NSTimeInterval)duration{
    _duration = duration;
    _durationLabel.text = [NSString timeTextFromSeconds:_duration];
}

-(void)UIChangeByUpdateCurTime:(NSTimeInterval)curTime{
    
    _justUIChange = YES;
    _progressSlider.value = curTime / _duration;
    _justUIChange = NO;
    
    _curTimeLabel.text = [NSString timeTextFromSeconds:curTime];
}

@end
