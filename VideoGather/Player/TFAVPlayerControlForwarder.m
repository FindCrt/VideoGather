//
//  TFAVPlayerControlForwarder.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFAVPlayerControlForwarder.h"
#import <objc/runtime.h>

@implementation TFAVPlayerControlForwarder

-(void)setPlayer:(AVPlayer *)player{
    _player = player;
    
    [_player addObserver:self forKeyPath:@"timeControlStatus" options:(NSKeyValueObservingOptionNew) context:nil];
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    __weak typeof(self) weakSelf = self;
    CMTime interval = CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC);
    
    [_player addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        if (duration != NAN) {
            [weakSelf.controlView UIChangeByGetDuration:duration];
        }
        [weakSelf.controlView UIChangeByUpdateCurTime:CMTimeGetSeconds(time)];
    }];
}

-(void)play{
    [self.player play];
}

-(void)pause{
    [self.player pause];
}

-(void)skipToProgress:(float)progress{
    NSAssert(progress >= 0 && progress <= 1, @"progress out range of [0,1]");
    CMTime duration = self.player.currentItem.duration;
    [self.player seekToTime:CMTimeMultiply(duration, progress)];
    
    if ([self.player timeControlStatus] == AVPlayerTimeControlStatusPaused) {
        [self.player play];
    }
}

-(void)goForwardWithTimeInterval:(NSTimeInterval)interval{
    CMTime curTime = self.player.currentTime;
    [self.player seekToTime:CMTimeAdd(curTime, CMTimeMakeWithSeconds(interval, curTime.timescale)) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    if ([self.player timeControlStatus] == AVPlayerTimeControlStatusPaused) {
        [self.player play];
    }
}

-(void)goBackWithTimeInterval:(NSTimeInterval)interval{
    CMTime curTime = self.player.currentTime;
    [self.player seekToTime:CMTimeSubtract(curTime, CMTimeMakeWithSeconds(interval, curTime.timescale)) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    if ([self.player timeControlStatus] == AVPlayerTimeControlStatusPaused) {
        [self.player play];
    }
}

-(void)changePlayRate:(float)rate{
    self.player.rate = rate;
}

#pragma mark - observe player status

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"timeControlStatus"]) {
        AVPlayerTimeControlStatus status = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerTimeControlStatusPaused) {
            [_controlView UIChangeBypause];
        }else if(status == AVPlayerTimeControlStatusPlaying){
            [_controlView UIChangeByplay];
        }
    }else if ([keyPath isEqualToString:@"status"]){
        AVPlayerStatus status = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            [self.controlView UIChangeByGetDuration:CMTimeGetSeconds(self.player.currentItem.duration)];
            
            //TODO:The success of changing rate raly on those properties.
            NSLog(@"canPlayFastForward :%@\n canPlayFastForward :%@\n canPlayReverse:%@\n canPlayFastReverse:%@\n canPlaySlowReverse:%@\n",
                  self.player.currentItem.canPlayFastForward?@"YES":@"NO",
                  self.player.currentItem.canPlaySlowForward?@"YES":@"NO",
                  self.player.currentItem.canPlayReverse?@"YES":@"NO",
                  self.player.currentItem.canPlayFastReverse?@"YES":@"NO",
                  self.player.currentItem.canPlaySlowReverse?@"YES":@"NO");
        }
    }
}

-(void)dealloc{
    [_player removeObserver:self forKeyPath:@"timeControlStatus"];
    [_player removeObserver:self forKeyPath:@"status"];
}

@end
